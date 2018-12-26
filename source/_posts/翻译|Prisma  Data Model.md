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

### 实例
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

### 构建 data model 模块

有几种可以使用的模块用于描述 data model

- `Types` 包含fields,用于把类似的实体分组. 每个data model 中的 type 都被映射到数据库的表和 CRUD操作,然后添加的 graphQL 的 schema 中
- `Relations` 描述 typee 之间的关系
- `Interfaces`属于抽象 types,包含了一组特定的字段, type在实现时必须要遵循. 现在 interface 还不能由用户定义.但是已经有这样的需求.
- 特定的`directives`指令,包含不同的使用用例, 例如 type 约束或者是级联删除的行为.

接下里的内容就是描述这些构建块的具体细节问题

## Prisma 的 database 和 data model

刚开使用 GraphQL和 Prisma时, `.graphql`文件的数量会让你不是所措.然而理解每个文件扮演的角色又是很关键的问题.
总体上讲,一个`graphql`文件可以包含下面的内容:
- GraphQL 的操作(例如  query, mutate或者 subscriptions)
- 使用 SDL 定义的 GraphQL type

如果要区分 Prisma database schema 和 data model的话,只有后者是有关联的!


现在这一很重要`data model 并不是实际的 GraphQL schema`,虽然也是用 SDL定义的,但是缺少 root types,所以不能生成实际的 API 操作符! Prisma 只是使用 data model作为一个硬工具表达一下具体的 data model 的外观.

正如上面提到的, Prisma 会生成实际的 GraphQL schema,包含`query`,`mutation`,`subscription` 三种 root type. 生成的 `prisma.graphql`文件被称为 ** Prisma database schema **.注意了,一定不要修改这个文件.这是系统自己生成的.

作为实例,看看一个最简单的 data model:

`datamodel graphql`

```js
type User {
  id: ID! @uniue
  name: String!
}
```

如果部署了 Prisma 的服务, Prisma 将会生成服务所需的一些 API:

`prisma.graphql`

```js
type Query {
  users(where: UserWhereInput, orderBy: UserOrderByInput, skip: Int, after: String, before: String, first: Int, last: Int): [User]!
  user(where: UserWhereUniqueInput!): User
}

type Mutation {
  createUser(data: UserCreateInput!): User!
  updateUser(data: UserUpdateInput!, where: UserWhereUniqueInput!): User
  deleteUser(where: UserWhereUniqueInput!): User
}

type Subscription {
  user(where: UserSubscriptionWhereInput): UserSubscriptionPayload
}
```

>其实在生成的 Graphql server 中还有一个`.graphql`文件, 这个文件被称为 application shema. 这里定义的 API是`实际暴露给最终用户的`.   Prisma 的 API 就作为 "query egine"来实际执行操作. 

所以,一个 基于PRISMA的Graphql server实际包含两个 API.可以认为是服务的两个数据层:
- Aplication layer: 定义客户端可以使用的操作
- Database layer: 定义 Prisma database 的服务

## Object types
object type(简称为 type)定义了实现data model 的实际组成部分. 用于代表应用主域的实体.
如果你很熟悉 SQL databases,可以把 type 看成是 关系型数据库的 table,一个 type 有一个名字,一个或者多个字段.
type的实例称为 *node*,这个术语指的是 data graph 中的 node. 在 data model 中定义的每个 type和 Prisma生成的 database schema 很类似.

### 定义一个 object type

用`type`关键字定义一个object type

```js
type Article {
  id: ID! @unique
  text: String!
  isPublished: Boolean @default(value: "false")
}
``` 

上面的 type 定义包含下面的属性:
- Name:`Article`
- Fields: `id`,`text`,`isPublished`(默认值是`false`)

### 为 type 生成 API 操作符

在 datamodel 中定义的 type 会影响 prisma graphql API 的生成. 
- queries
- mutations
- subscriptions

## Fields

Fields 是构建 type的基础块. 每个字段由名字来引用, 要么是标量,要么是 relation 字段

### 标量类型
#### String
`String`承载 text,可以用于 username,blog的正文,或者代表 txt 的内容

注意: String在共享的 cluster 中容量是256kb.可以通过 clusters 的配置来扩增.

在 query 或者 mutation 中, String字段要用双引号定义:`string:"some-string"`
#### Integer
`Int`是没有小数位的数字,可以用来储存成分重量, 或者最小年龄等. 
  `int:42`
#### Float
`float`是有小数位的数字,  `float:42`,`float:4.2`
#### Boolean
`boolean:true`,`boolean:false`
#### DateTime
`DateTime` type 用来保存日期或者时间值. 某人的出生日期就是一个例子.
在`query`和`mutations`中,`DateTime`字段要定义为`ISO8601 format`.
- `datetime:"2015"`
#### Enum 枚举
用于定义服务的范围
和 boolean 一样,有一套预设值,不同点是可以自己设置.   限定为`191个字符`
#### JSON
有时候要储存松散的数据结构,可以可以用 JSON.
`json: "{\"int\": 1, \"string\": \"value\"}"`
#### ID
25个字符串,基于 cuid.
### Type modifiers
#### List
`listString: ["a string", "another string"], listInt: [12, 24]`.
#### Required
fields 可以被标记位 required(non-null).  `name:String!`

### field 限定
字段可以使用特定的字段限定
#### Unique
连个 node,不能有同样的值.唯一例外是`null`.
>通常 User type 的`email`是唯一的

只有开始的191个字符是唯一的, 并且是区分大小写的. 
```js
type User {
  email: String! @unique
  age: Int!
}
```

对于使用`@unique`限定的字段可以借此查询对应的 node.
例如可以返回拥有此 email 的用户节点:
```js
query {
  user(where: {
    email: "alice@graph.cool"
  }) {
    age
  }
}
```

#### 后续还有其他的限定条件加入

### Default Value
可以为标量设定默认值. `@default`指令

```js
type Story {
  isPublished: Boolean @default(value: "false")
  someNumber: Int! @default(value: "42")
  title: String! @default(value: "My New Post")
  publishDate: DateTime! @default(value: "2018-01-26")
}
```

一定要用双引号,即使不是字符串

### System fields

三个字段`id`,`createdAt`,`updatedAT`有特殊的意义. 在 datamodel 中是可选,但是在底层的数据库中会一直存在.
除非要是导入的数据, 否则, 这三个值在 graphql API 中是只读的.
## Relations
relation 定义了连接两个 type 的语法. 两个类型通过 relation fields 连接在一起.如果 relation 可能会混淆的时候,要使用`@relation`来区分开
连接自身的字段也可以
### Required relations

### `@relation` directive
有两个参数
- `name`: 用于识别 relation.
- `onDelete`:用于定义删除行为:
  - `SET_NULL`(default):设定 related node 为`null`
  - `CASCADE`:删除 related nodes.

实例:
```js
type User {
  id: ID! @unique
  stories: [Story!]! @relation(name: "StoriesByUser" onDelete: CASCADE)
}

type Story {
  id: ID! @unique
  text: String!
  author: User @relation(name: "StoriesByUser")
}
```

上面例子的删除行为:
- 当`User`node被删除以后, 与之有关的`Story` node 也被删除
- 当`Story` node被删除,只会从`User` 的`stories`列表中删除

#### 省略`@relation`指令
当两个 type 不会发生歧义的时候,可以不用写这个指令

```js
type User {
  id: ID! @unique
  stories: [Story!]!
}

type Story {
  id: ID! @unique
  text: String!
  author: User
}

```

- 当`User`删除掉, `author`中所有的相关`Story`都会被设为`null`.如果 author 被设定为 required,操作就会引发错误
- 当一个`Story`被删除掉以后,只会从`User` node  list 中删除

#### 在`@relation`指令中使用` name`参数

```js
type User {
  id: ID! @unique
  writtenStories: [Story!]! @relation(name: "WrittenStories")
  likedStories: [Story!]! @relation(name: "LikedStories")
}

type Story {
  id: ID! @unique
  text: String!
  author: User! @relation(name: "WrittenStories")
  likedBy: [User!]! @relation(name: "LikedStories")
}
```

#### 在`@relation`指令中使用`onDelete`参数

```js
type User {
  id: ID! @unique
  comments: [Comment!]! @relation(name: "CommentAuthor", onDelete: CASCADE)
  blog: Blog @relation(name: "BlogOwner", onDelete: CASCADE)
}

type Blog {
  id: ID! @unique
  comments: [Comment!]! @relation(name: "Comments", onDelete: CASCADE)
  owner: User! @relation(name: "BlogOwner", onDelete: SET_NULL)
}

type Comment {
  id: ID! @unique
  blog: Blog! @relation(name: "Comments", onDelete: SET_NULL)
  author: User @relation(name: "CommentAuthor", onDelete: SET_NULL)
}
```

看看三个不同的类型:

-  `User` node 被删除
   - 所有的`Comment` nodes 被删除
   - `Blog` node 也被删除
-  当`Blog` node 被删除,
   - 所有相关的`Comment`nodes被删除
   - 拥有`blog`字段的`User` node 被设置为空
-  当`Comment` node 被删除
   - 相关的`Blog` node会继续存在,`Comments`会从`comment` list 中删掉
   - 相关的`User`会一直存在, `Comment` node会从`comments` list 中删掉

#### 为 relations 生成 API 操作
- `relation queries` 会跨 types查询数据或者聚合 relation
- `nest mutations`  跨 types, create,connect,update upsert和 delete nodes
- `relation subscription` 改变 relation时获取通知

### GraphQL 指令

#### 临时性指令
#### renaming a type or field
`@rename(oldName:String!)`

```js
# renaming the `Post` type to `Story`, and its `text` field to `content`
type Story @rename(oldName: "Post") {
  content: String @rename(oldName: "text")
}
```






  









