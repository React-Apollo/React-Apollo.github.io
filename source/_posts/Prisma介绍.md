---
title: Prisma简介(翻译)
date: 2018-1-20 13:18:28
categories: 翻译
tags: [Graphcool,graphql]
---

{{TOC}}

# Prima简介
>用于数据库的开源GraphQL API抽象层.本来准备翻译 medium上面的简介,但是最后感觉也太简单了,说明不了太多问题.  总体上, Prisma 是位于 grpqh-client 和传统数据库或者 REST API 之间的应用层, 利用了 graphQL的强类型和 schema 的优点.在这个系统中, 核心是围绕`Schema`展开. 最终构建了灵活可用数据的CRUD 方法. 

**Prisma是GraphQL 数据库的代理，它可以把你的数据库转化为GraphQL API.** 你可以使用
### 基础构架
![Prisma 基础构架](https://ws3.sinaimg.cn/large/006tKfTcgy1foa02v3cioj30k3084dft.jpg)

1. 客户端作为数据的消费者, 可以使用 apollo-client 或者 relay
2. Graphql sever 是基于 graphql-yoga 的 webserver, 内核是 express
3. Prisma & Prisma bindings
4. Database




