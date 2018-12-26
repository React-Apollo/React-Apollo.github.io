---
title: 摘要|GraphQL Databases — A preview into the future of Graphcool
date: 2018-02-08 18:08:58
categories: 技术备忘
tags: [Graphcool,Prisma]
---

{{TOC}}

**GraphQL 数据库- Graphcool 未来展望**

###  构建 GraphQL 服务器的方法更加符合常规
### 定义的 GraphQL schema 如何映射到数据库
在 graphql的应用中有两层,一层是数据库层,一层是应用层(graphql发挥作用的地方).
可以作为 REST API 的"gateway",整合多个 API,或者是遗留的资源.
### GraphQL DataBase
- 使用 SDL 简单明了的进行数据模型管理
- 建立 GraphQL CRUD  API. 

![](https://ws3.sinaimg.cn/large/006tKfTcgy1fo97k4qwvij30bv05w0sl.jpg)

#### Graphcool database service

- `graphcool.yml`:graphcool服务的根配置. 在 Prisma里结构已经改变了
- `database/datamodel.graphql`:定义应用的数据模型,之前的版本叫`types.graphql`
- `database/schema.grphql`:这是根据命令自动生成的. 包括完整的根据 datamodel生成的 database schema.绝大多数都是 CRUD 操作的方法.是应用的基础.

#### Application(GraphQL Server)
`这个一部分是之前的版本没有的部分` 所以要留心.
新版本(Prisma)现在只是覆盖数据库层.所以需要额外的层作为实际的 web 服务. 这就是这个一部分的目的. 这一部分也有 schema.graphql,包含了应用的 schema. 定义了最终暴露给客户端的 API.
#### graphQL  配置.
因为现在有两个独立的 GraphQL API(一个是应用的,一个是数据库的).
添加工具管理这两个部分是很有意义的.
`grqphqlconfig.yml`就是配置文件

在 database/datamodel中会生成完整的 CRUD 操作, 但是如果不想完全暴露给应用. 可以对其进行进行裁剪.  `应用的 schema 就是这个目的`.

 




