---
title: 摘要|GraphQL Persisted Queries using GET Requests
date: 2018-03-11 10:28:49
categories: 技术备忘
tags: [GraphQL,Persisted Queries]
---
> [原文:GraphQL Persisted Queries using GET Requests](https://medium.com/@coreyclark/graphql-persisted-queries-using-get-requests-8a6704aba9eb)

## 摘要总结

**`通过express 的中间件实现了 graphql Persisted Queries,在前端查询时使用的普通的GET请求,带有hash变量和具体变量, hash变量用于从服务器获取到对应的查询或者突变 schema,然后和具体的变量组合成真正的查询字符窜, 之后实施真正的 Graphql 查询工作, 并返回信息给前端`**

![具体的实现示意图](https://ws2.sinaimg.cn/large/006tNc79gy1fp8nh5be71j30mt0f9aaz.jpg)

## 实现要点:

### 1. 构建的hash 和查询的映射
`extracted_queries.js`

```js
module.exports = {
 1: `query Greeting($name: String!) {
      greeting(name: $name) { 
       name
       text   
      }
    }` 
}
```

### 2. 构建 Presist Query 中间件
`persistedQueries.js`

```js
const { omit } = require('ramda')
const queryMap = require('./extracted_queries.js')
const persistedQueries = (req, res, next) => {
  const { hash = '' } = req.query
  
  if (!hash) return next()
  const query = queryMap[hash]
  
  if (!query) {
    res.status(400).json({ error: [{}] })
    return next(new Error('Invalid query hash'))
  }
  req.query = {
    query,
    variables: omit(['hash'], req.query)
  }
  next()
}
module.exports = persistedQueries
```

如果 hash存在,就提取出查询字符串和变量组成新的查询


### 3. 构建 graphql server

```js
const express = require('express')
const bodyParser = require('body-parser') 
const playground = require('graphql-playground-middleware-express').default
const { graphqlExpress, graphiqlExpress } = require('apollo-server-express')
const { makeExecutableSchema } = require('graphql-tools')
const persistedQueries = require('./persistedQueries')
const typeDefs = require('./schemas')
const resolvers = require('./resolvers')
const port = 4000
const app = express()
const schema = makeExecutableSchema({ typeDefs, resolvers })
app.use(
  '/graphql', 
  bodyParser.json(),
  persistedQueries,  //对 get请求进行匹配操作.匹配的查询进入具体的查询操作
  graphqlExpress({ schema })
)
//playground实现
app.use(
  '/playground', 
  playground({ endpoint: '/graphql' })
)
app.listen(port, () => console.log(`listening on port: ${port}`))
```


## 构想

**`如果是常规的 Redux 构架, REST API太多, 造成 Action过多, 如果是使用上述的方法, 可以把一个大的页面的数据查询组合成一个单独的 REST请求. 简化了前端的 Action这样还可以使用不同的 GraphQL的数据`**