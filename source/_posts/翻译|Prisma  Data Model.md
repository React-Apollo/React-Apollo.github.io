---
title: 翻译|Prisma  Data Model
date: 2018-02-09 11:02:23
categories: 翻译
tags: [Graphcool,graphql]
---

{{TOC}}

## 概览
Prisma 使用  [`GraphQL Schema Definition Language`](https://blog.graph.cool/graphql-sdl-schema-definition-language-6755bcb9ce51) 定义数据模型.数据模型可以写在一个或多个`.graphql`文件中.在内部它是 Prisma 生成实际数据库 schema 的基础.如果只使用单个的定义文件,可以被称为`datamodel.graphql`.

`.graphql`文件需要在`prisma.yml`中声明. 例如:

```
datamodel:
  - types.graphql
  - enums.graphql
```

如果是单个文件:
```
datamodel:datamodel.graphql
```

data model 是 基于Prisma服务的 GraphQL API 的基础. Prisma会以此生成一套强有力的 Graphql Schema(被称为 **Prisma data schema**),为 data model 定义了全部的 CRUD 操作.

#### 实例
一个简单的`datamodel.graphql`文件:

```js
type Tweet {
  id: ID! @unique
  createdAt: DateTime!
  text: String!
  owner: User!
  location: Location!
}

type User {
  id: ID! @unique
  createdAt: DateTime!
  updatedAt: DateTime!
  handle: String! @unique
  name: String
  tweets: [Tweet!]!
}

type Location {
  latitude: Float!
  longitude: Float!
}
```

实例展示了一些data model 的重要概念:

- 三个类型 `Tweet`,`User`,`Location`被映射到数据库的表中
- `User`,`Tweet`之间是双向关系
- `Tweet`到`Location`是单向关系
- 除了 `User`的 `name`字段,所有的字段都是必须的(用!表示)
- `id`,`createdAt`,`updateAt`字段由 Prisma 管理,在 GraphQL API 中只读

创建和更新 datamodel 和修改文本文件一样简单.一旦 datamodel 的修改达到你的需求,可以执行`prisma deploy`命令 :
```
$ prisma deploy

Changes:

  Tweet (Type)
  + Created type `Tweet`
  + Created field `id` of type `GraphQLID!`
  + Created field `createdAt` of type `DateTime!`
  + Created field `text` of type `String!`
  + Created field `owner` of type `Relation!`
  + Created field `location` of type `Relation!`
  + Created field `updatedAt` of type `DateTime!`

  User (Type)
  + Created type `User`
  + Created field `id` of type `GraphQLID!`
  + Created field `createdAt` of type `DateTime!`
  + Created field `updatedAt` of type `DateTime!`
  + Created field `handle` of type `String!`
  + Created field `name` of type `String`
  + Created field `tweets` of type `[Relation!]!`

  Location (Type)
  + Created type `Location`
  + Created field `latitude` of type `Float!`
  + Created field `longitude` of type `Float!`
  + Created field `id` of type `GraphQLID!`
  + Created field `updatedAt` of type `DateTime!`
  + Created field `createdAt` of type `DateTime!`

  TweetToUser (Relation)
  + Created relation between Tweet and User

  LocationToTweet (Relation)
  + Created relation between Location and Tweet

Applying changes... (22/22)
Applying changes... 0.4s
```

```

```





