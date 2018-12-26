---
title: 摘要|Full-stack React + GraphQL Tutorial(part1)
date: 2018-02-10 20:10:01
categories: 技术备忘
tags: [Grahpql,Apollo-client]
---

{{TOC}}
>这个是之前看到apollo-client 的入门文章,随着学习,回过头来看看,觉得非常有意思
 不准备全部翻译,有些有用的地方强调一下
### 系列文章
- Part 1 (this part): Setting up a simple client
- Part 2: Setting up a simple server
- Part 3: Writing mutations and keeping the client in sync
- Part 4: Optimistic UI and client side store updates
- Part 5: Input types and custom cache resolvers
- Part 6: Subscriptions on the server
- Part 7: GraphQL Subscriptions on the client
- Part 8: Pagination
####  配置
使用 create-react-app 的方法,很简单,而且可以部署到 github, 因为这是静态文件,嵌入的 js打包文件. 

app.js 文件修改如下-导入一个列表组件:
```js
import React, { Component } from 'react';
 import logo from './logo.svg';
 import './App.css';
const ChannelsList = () =>
     (<ul>
       <li>Channel 1</li>
       <li>Channel 2</li>
     </ul>);
class App extends Component {
   render() {
     return (
       <div className="App">
         <div className="App-header">
           <img src={logo} className="App-logo" alt="logo" />
           <h2>Welcome to Apollo</h2>
         </div>
         <ChannelsList />
       </div>
     );
   }
 }
export default App;
```

#### 编写 graphql  schema 文件

```
export const typeDefs = `
type Channel {
   id: ID!                # "!" denotes a required field
   name: String
}
# This type specifies the entry points into our API. In this case
# there is only one - "channels" - which returns a list of channels.
type Query {
   channels: [Channel]    # "[]" means this is a list of channels
}
`;
```
这是标准的做法,如果是定义了一个 schema 实体, 返回列表就是一个数组
根据这个 schmea 可以编写查询

```
query ChannelsListQuery {
  channels {
    id
    name
  }
}
```

对组件进行包装:

```
const channelsListQuery = gql`
   query ChannelsListQuery {
     channels {
       id
       name
     }
   }
 `;
const ChannelsListWithData = graphql(channelsListQuery)(ChannelsList);
```

由于 apollo-client 利用了网络层的状态标志,省去了自己构建的麻烦:
```
const ChannelsList = ({ data: {loading, error, channels }}) => {
   if (loading) {
     return <p>Loading ...</p>;
   }
   if (error) {
     return <p>{error.message}</p>;
   }
   return <ul>
     { channels.map( ch => <li key={ch.id}>{ch.name}</li> ) }
   </ul>;
 };
```

`直接可以使用的loading 和 error 标记`


后面的模拟数据部分,新版已经改进了,不能再使用

 

