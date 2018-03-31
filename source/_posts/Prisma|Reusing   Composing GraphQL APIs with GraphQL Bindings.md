---
title: 博客模板
date: 2018-03-31 12:57:01
categories: 技术备忘
tags: [Graphcool,Prisma]
---
# Prisma|Reusing & Composing GraphQL APIs with GraphQL Bindings

>[**`原文地址`**](https://blog.graph.cool/reusing-composing-graphql-apis-with-graphql-bindings-80a4aa37cff5)

![](https://cdn-images-1.medium.com/max/1600/1*eM-5mFvSz4MEZpqiOfRGOA.jpeg)

>使用 GraphQL binding,不需要了解细节问题,可以访问到 GraphQL API 的功能


## 什么是GraphQL bindings?

**graphql binding是构建的模块,可以让你在自己的 GraphQL Server中嵌入已经村啊在的 GraphQL APIS** 像是搭积木的块. 

创建一个 GraphQL API binding的核心思想是提供一个专用的(dedicated)对象,来代表 API 的功能. 这个对象暴露的方法是 GraphQL schema中定义查询的镜像. 

不需要在手动构建查询字符串,然后发送到 API(通过`fetch`或者 GraphQL客户端,例如`graphql-request`),只需要使用特定程序语言"构建"查询,调用查询方法即可. 

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fpvx917y5hj317s0e60um.jpg)
在使用 typed 语言时, GraphQL binding 会把 GraphQL API 的 type 映射到对应的编程语言上. 

GraphQL最具威力的地方就是它的强类型 schema. 然而通过字符串发送查询时, 优势就没有了. Binding可以让我们重新获取这一优势

## GraphQL binding 最简单的例子

假设有如下的 schema:

```graphql
type Query {
   hello(name:String):String!
}
```


现在,在使用 binding 和这个 schema 交互时,不需要构建查询字符串. 只需要在对象`helloWroldBinding`对象上调用 代表`hello` 查询的函数即可:

```js
helloWorldBinding.query.hello()
  .then(result => console.log(result))

helloWorldBinding.query.hello({ name: 'Nikolas' })
  .then(result => console.log(result))
```


调用函数时,对象的查询会被发送到 API:

```graphql
# helloWorldBinding.query.hello()
query {
  hello
}

# helloWorldBinding.query.hello({ name: 'Nikolas' })
query {
  hello(name: "Nikolas")
}

```


## 使用 GraphQL binding 的好处

- `简化和抽象 API`
- `对IDE的支持`
- `可重用`
- `边编译边做错误检查`
- `语言通用性`

## 构建和共享 GraphQL bindings

使用`graphql-binding` package

>这个包的核心是一个`Binding`类,这个类接收 Graphql shcema 作为构造参数. 

这个例子比较简单,实际使用中 schema 需要是远程的 schemas


```js
const { makeExecutableSchema } = require('graphql-tools')
const { Binding } = require('graphql-binding')

const users = [
  {
    name: 'Alice',
  },
  {
    name: 'Bob',
  },
]

const typeDefs = `
  type Query {
    findUser(name: String!): User
  }
  type User {
    name: String!
  }
`

const resolvers = {
  Query: {
    findUser: (parent, { name }) => users.find(u => u.name === name),
  },
}

const schema = makeExecutableSchema({ typeDefs, resolvers })
```

上面是创建 schema 的过程,有了 schema 就可以创建`Binding`实例了:


```js
const findUserBinding = new Binding({
  schema,
})
```

最后就可以使用 binding 对象`findUserBinding`来访问 schema 的`findUser`查询:

```js
findUserBinding.query.findUser({name:'Bob'})
```


## 为 GraphQL bidings 生成静态类型

### 使用 GraphQL CLI 生成 TS 类型

GraphQL  CLI  包含有`graphql prepare`命令,可以轻松生成静态类型

第一步添加静态类型生成

```yaml
projects:
  helloworld:
    schemaPath: schema.graphql
    extensions:
      prepare-binding:
        output: helloworld.ts
        generator: binding-ts
```


- `schemaPaht`:指向 GraphQL schema.
- `extensions.prepare-binding.output`: 存放生成的 bindings
- `extensions.prepare-binding.generator`: generator 使用的地方.. 存在的 generator:`binding-js`&`binding-ts`可以用于任何的 GraphQL API.`prisma-js`&`prisma-ts`为Prisma 服务提供额外的便利性

假设你的schema 位于`shcema.graphql`,你可以调用`graphql prepare`命令生成 TypeScript bindings. 放置在`generated/helloworls.ts`:

```ts
import { Binding as BaseBinding, BindingOptions } from 'graphql-binding'
import { GraphQLResolveInfo } from 'graphql'

export interface User {
  name: String
}

/*
The `Boolean` scalar type represents `true` or `false`.
*/
export type Boolean = boolean

/*
The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text.
*/
export type String = string

export interface Schema {
  query: Query
}

export type Query = {
  findUser: (args: { name: String }, context: { [key: string]: any }, info?: GraphQLResolveInfo | string) => Promise<User | null>
}

export class Binding extends BaseBinding {
  
  constructor({ schema, fragmentReplacements }: BindingOptions) {
    super({ schema, fragmentReplacements });
  }
  
  query: Query = {
    findUser: (args, context, info): Promise<User | null> => super.delegate('query', 'findUser', args, context, info)
  }
}
```

这个文件不能手动修改.

##  新型的ORM: GraphQL database bindings

GraphQL bindings 可以在 database layer 和 application layer 之间生成映射. 在上下文中,可以在 server 中扮演 ORM的角色

例如,使用 Prisma 作为 graphql database layer.你可以直接使用`prisma-binding`,或者使用`prisma-ts`生成静态类型

一下是`prisma-binding`的工作.假设有一个简单的 data model

```graphql
type User{
   id:ID! @unique
   name:String!
}   
```

在部署以后,会自动生成 Prisma database schema. 这个 schema 定义了 `User`类型的 CURD 操作.

```graphql
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

现在可以实例化`Prisma`类,

```js
const { Prisma } = require('prisma-binding')

const prisma = new Prisma({
  schemaPath: 'generated/prisma.graphql',
  endpoint: 'hhttp://localhost:60000/helloworld/dev',
  secret: 'my-super-secret-secret' // defined in prisma.yml 
})
```


`prisma`实例现在作为 query,mutations和 subscription的代理. 实例如下:

```js
// Retrieve `name` of a specific user
prisma.query.user({ where { id: 'abc' } }, '{ name }')

// Retrieve all fields of all users
prisma.query.users()

// Create new user called `Sarah` and retrieve the `id`
prisma.mutation.createUser({ data: { name: 'Sarah' } }, '{ id }')

// Update name of a specific user and retrieve the `id`
prisma.mutation.updateUser({ where: { id: 'abc' }, data: { name: 'Sarah' } }, '{ id }')

// Delete a specific user
prisma.mutation.deleteUser({ where: { id: 'abc' } })
```

实际新版的 prisma 就是这个思路.

==完==
