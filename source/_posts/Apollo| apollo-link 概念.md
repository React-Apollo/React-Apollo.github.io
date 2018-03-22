---
title: Apollo| apollo-link 概念
date: 2018年3月22日下午9:33:27
categories: 技术备忘
tags: [GraphQL,Apollo]
---
> `这个概念实际和 redux的 middleware 类似, 就是在数据流处理中的增加环节`
# 概念总览

Apollo Link设计目的是组合围绕 GraphQL数据操作的 actions.每个link代表着创建复杂数据控制流程的子功能.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fpld6p0g2yj30di01pjr7.jpg)

基础是一个函数接收一个操作,返回一个 observable. 一个操作对象有一下的信息:
- `① query` :`DocumentNode`(解析 GraphQL Operation)描述发生的操作
- `② variables`:伴随 operation 发送的变量映射
- `③ operationName`: 查询的名字,可以为 null
- `④ extensions`:发送到 server 的数据在 Store的映射
- `⑤ getContext`: 返回请求 context 的函数. 被 link 用来决定执行哪一个 actions
- `⑥ setContext`: 创建一个新的 context 对象,或者是接受之前的 context,返回一个新的 context. 和React 的`setState`行为类似
- `⑦ toKey`: 把当前的操作转为字符串作为 uniq的函数

可以链式操作这些操作. compose action,从而实现复杂的操作逻辑

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fpldczvm6gj30la02ggli.jpg)
上图中最后 link的终点是 server,实际 结果可以来自于任何地方

## Request

link 的核心是`request`方法,接收参数如下:

- `operation`: 传递给 link的操作
- `forward`: 声明链中接下来的 link

##  Context

link 可以形成链式操作, 所以需要在链中传递一些数据.
context 的操作和 React 的`setState`类似

```js
const timeStartLink = new ApolloLink((operation, forward) => {
  operation.setContext({ start: new Date() });
  return forward(operation);
});

const logTimeLink = new ApolloLink((operation, forward) => {
  return forward(operation).map((data) => {
    // data from a previous link
    const time = new Date() - operation.getContext().start;
    console.log(`operation ${operation.operationName} took ${time} to complete`);
    return data;
  })
});

const link = timeStartLink.concat(logTimeLink)
```

conxt 可以在 operation 开始的时候发送.例如可以在执行 query时 发送 context

```js
const link = new ApolloLink((operation, forward) => {
  const { saveOffline } = operation.getContext();
  if (saveOffline) // do offline stuff
  return forward(operation);
})

const client = new ApolloClient({
  cache: new InMemoryCache()
  link,
});

// send context to the link
const query = client.query({ query: MY_GRAPHQL_QUERY, context: { saveOffline: true }});
```




