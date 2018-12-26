---
title: EcoSystem|如何用 GraphQL包装 REST API
date: 2018-02-23 11:54:55
categories: 技术备忘
tags: [Graphcool,Prisma]
---
![](https://ws4.sinaimg.cn/large/006tNc79gy1foq8s59sikj318g0nt3zd.jpg)
>数组和对象的处理是常规编程中处理的主要内容, 可说是数据的表现形式,但是原始数据可能达不到我们的要求,所以有很多的处理方法. 我想在 GraphQL的模式下,在 resolver 中处理 REST API,或者其他的 graphQL server 的数据,出发点是类似的.数据的本质并没有改变.GrahQL 的核心是提供了:

  - 单一的入口
  - 严格的类型约束
  - 灵活的查询构成

所以如果我们要使用 `graphQL` 包装 `REST API`,从 `REST API`返回的数据必须要遵循 GraphQL 的核心概念. 保证严格约束下的灵活性. 核心概念就如此.  

1. Analyze the data model of the REST API
2. Derive the GraphQL schema for the API based on the data model
3. Implement resolver functions for the schema

### resolver
resolver 函数只是简单的 express 服务器, 可以在其中调用任何的接口,根据 schema 返回数据. 复杂的操作都要在 resolver中实现. 
`Prisma`的内核其实就是一个 Node.js   Express server.  对于简单的schema, 自动生成了很多的 CURD方法,现阶段从 mysql 数据库获取数据,然后按照 schema的要求返回 json 数据.   这个 server, 就是 graphql-yoga.  简单和容易体现在, resolvers 是系统自动生成的,还是我们来编写. 




