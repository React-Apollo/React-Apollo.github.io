---
title: GraphQL Server Basics: The Network Layer
date: 2018-02-08 12:12:39
categories: 技术备忘
tags: [Graphcool,graqhql]
---

{{TOC}}
#GraphQL Server Basics: The Network Layer
[GraphQL Server Basics: The Network Layer](https://blog.graph.cool/graphql-server-basics-the-network-layer-51d97d21861)
## Graphql 通过 HTTP协议提供服务 ##

以 schema 为核心,定义好了以后后端的 schema和 resolver 之后, 如何实现 Graphql 就是问题了

### express.js 的中间件
Express 中间件接收`req`,`res`,`next`函数.
因为 express 可以处理 http 请求, Graphql 定义的 schema 和 resolver 提供了功能, 需要的就是把他们粘合起来

中间的桥梁有`express-grahpql`,`apollo-server`.本质上他们都是 express 的中间件

#### GraphQL 中间件
GraphQL 结合了 HTTP请求和 Graphlql.js
`express-grahpql`是 facebook 版本的 GraphQL的中间件,主要有两个作用:
1. 解析请求中的查询和 mutate, 转发给 `graphql`函数,最终做处理
2. 把结果附加到 `res`对象,返回给客户端

```js
const express = require('express')
const graphqlHTTP = require('express-graphql')
const { GraphQLSchema, GraphQLObjectType, GraphQLString } = require('graphql')

const app = express()

const schema = new GraphQLSchema({
  query: new GraphQLObjectType({
  name: 'Query',
  fields: {
    hello: {
      type: GraphQLString,
      resolve: (root, args, context, info) => {
        return 'Hello World'
      }
    }
  }
})

app.use('/graphql', graphqlHTTP({
  schema,
  graphiql: true // enable GraphiQL
}))

app.listen(4000)
```

#####  apollo-server 与 express-graphql 类似

两者类似, apollo-server 提供了对更多框架的支持而已.

##### graphql-yoga
这是最容易使用的,就是 Graphql 背后的中间件

```js
const { GraphQLServer } = require('graphql-yoga')

const typeDefs = `
  type Query {
    hello: String!
  }
`

const resolvers = {
  Query: {
    hello: (root, args, context, info) => 'Hello  World'
  }
}

const server = new GraphQLServer({ typeDefs, resolvers })
server.start() // defaults to port 4000
```




