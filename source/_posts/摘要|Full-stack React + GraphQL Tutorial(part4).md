---
title: 摘要|Full-stack React + GraphQL Tutorial(part4)
date: 2018-02-10 20:23:46
categories: 技术备忘
tags: [Grahpql,Apollo-client]
---

{{TOC}}
>这个是之前看到apollo-client 的入门文章,随着学习,回过头来看看,觉得非常有意思
 不准备全部翻译,有些有用的地方强调一下
### 系列文章
- Part 1 : Setting up a simple client
- Part 2:  Setting up a simple server
- Part 3: Writing mutations and keeping the client in sync
- Part 4: (this part)Optimistic UI and client side store updates
- Part 5: Input types and custom cache resolvers
- Part 6: Subscriptions on the server
- Part 7: GraphQL Subscriptions on the client
- Part 8: Pagination
### Mutation 和延迟
网络操作存在不可预测的延迟,这个没有办法去估计和预测. 只有通过一定的策略去提供更为友好的操作方法.
#### mutation 之后的 store 更新
针对 mutation 和其他需要根据客户端的操作来更新 store的操作, Apollo-client提供了一套有力的工具:`readQuery`,`writeQuery`,`readFragment`和`writeFragment`.

客户端的添加操作,可以如下操作,先写入缓存里

```js
const handleKeyUp = (evt) => {
    if (evt.keyCode === 13) {
      evt.persist();
      mutate({ 
        variables: { name: evt.target.value },
        update: (store, { data: { addChannel } }) => {
            // Read the data from the cache for this query.
            const data = store.readQuery({query: channelsListQuery });
            // Add our channel from the mutation to the end.
            data.channels.push(addChannel);
            // Write the data back to the cache.
            store.writeQuery({ query: channelsListQuery, data });
          },
      })
      .then( res => {
        evt.target.value = '';  
      });
    }
  };
``` 

这样一旦, mutation 操作完成,可以立刻得到结果,不会有延迟存在.
![](https://ws1.sinaimg.cn/large/006tNc79gy1fobmr5zy1sj30c2092q2w.jpg)

实际的延迟仍然存在,但是通过技巧处理了这个问题

#### Optimistic UI

apollo-client提供了 Optimistic UI 来完美的解决这个问题

途径通过在mutation中添加`optimisticResponse`属性.

```js
mutate({ 
  variables: { name: evt.target.value },
  optimisticResponse: {
     addChannel: {
       name: evt.target.value,
       id: Math.round(Math.random() * -1000000),
       __typename: 'Channel',
     },
   },
   update: ...
})
```

为了让用户知道,添加的数据还没有被服务器确认,还需要一些小技巧保持条目也 optimistic
我们在上面生成了一个负的 id 

```js
id: Math.round(Math.random() * -1000000),
```

为了让未经服务器确认的消息和真实的消息 有所区分,要添加额外的 CSS:

```js
return (
    <div className="channelsList">
      <AddChannel />
      { channels.map( ch => 
        (<div key={ch.id} className={'channel ' + (ch.id < 0 ? 'optimistic' : '')}>{ch.name}</div>)
      )}
    </div>
  );
```

```
div.optimistic {
  color: rgba(255, 255, 255, 0.5);
}
```

注意:这里的 id 并不重要,重要的是显示的内容,所以用了一个 id 为负值的参数,既区分了真实和模拟的数据,又据此添加了对应的样式.

当真实的数据从服务器返回以后,会替代负id的样式, 就确认mutation 了.



