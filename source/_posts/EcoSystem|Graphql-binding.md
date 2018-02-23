---
title: EcoSystem|Graphql-binding
date: 2018-02-23 08:30:29
categories: 技术备忘
tags: [graphql,Prisma]
---

{{TOC}}

>🔗 `graphql-binding` 可以在 `graphql server` 中嵌入`grahql API`
核心概念是通过为 GraphQL API 创建一个对象,表现出 API 的功能. 这个对象暴露的方法和GraphQL API schema 中定义的查询方法是镜像关系.

### Install

```js
yarn add graphql-binding
```

### API
#### constructor

```js
constructor(options: BindingOptions): Binding
```

| Key | Required |  Type | Default | Note |
| ---  | --- | --- | --- | --- |
| `schema` | Yes | `GraphQLSchema` |  - | The executable [GraphQL schema](https://blog.graph.cool/ac5e2950214e) for binding  |
| `fragmentReplacements` | No | `FragmentReplacements` |  `{}` | A list of GraphQL fragment definitions, specifying fields that are required for the resolver to function correctly |
| `before` | No | `() => void` |  `(() => undefined)` | A function that will be executed before a query/mutation is sent to the GraphQL API |
| `handler` | No | `any` |  `null` | The [`handler`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy/handler) object from [JS Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy) |
| `subscriptionHandler` | No | `any` |  `null` | ... |


#### query&mutation

```js
binding.query.<rootField>: QueryMap<any> // where <rootField> is the name of a field on the Query type in the mapped GraphQL schema
binding.mutation.<rootField>: QueryMap<any> // where <rootField> is the name of a field on the Mutation type in the mapped GraphQL schema
```

`binding`对象暴露出两个接口 `query`,`mutate`可以用于执行操作.分别接收三个参数


 Name | Required |  Type | Note |
| ---  | --- | --- | --- |
| `args` | No | `[key: string]: any` |  An object that contains the arguments of the root field |
| `context` | No | `[key: string]: any` |  The `context` object that's passed down the GraphQL resolver chain; every resolver can read from and write to that object |
| `info` | No | `GraphQLResolveInfo` &#124; `string` |  The `info` object (which contains an AST of the incoming query/mutation) that's passed down the GraphQL resolver chain or a string containing a [selection set](https://medium.com/front-end-developers/graphql-selection-sets-d588f6782e90) |

#### 实例
假设有下面的 schema

```js
type Query {
  user(id: ID!): User
}

type Mutation {
  createUser(): User!
}
```

```js
binding.query.user({ id: 'abc' })
binding.mutation.createUser()
```

```js
findUser(parent, args, context, info) {
  return binding.user({ id: args.id }, context, info)
}

newUser(parent, args, context, info) {
  return binding.createUser({}, context, info)
}
```

##### subscription
```js
binding.subscription.<rootField>(...):  AsyncIterator<any> | Promise<AsyncIterator<any>> 
// where <rootField> is the name of a field 
//on the Subscription type in the mapped GraphQL schema
```

### 简单实例

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

const findUserBinding = new Binding({
  schema,
})

findUserBinding.findUser({ name: 'Bob' })
  .then(result => console.log(result))
```

### `与 Prisma 的联系`

`graphcool-binding(prisma)` 是这个版本的实现方案

```js
// Instantiate `Prisma` based on concrete service
const prisma = new Prisma({
  typeDefs: 'schemas/database.graphql',
  endpoint: 'https://us1.prisma.sh/demo/my-service/dev'
  secret: 'my-super-secret-secret'
})

// Retrieve `name` of a specific user
prisma.query.user({ where { id: 'abc' } }, '{ name }')

// Retrieve `id` and `name` of all users
prisma.query.users(null, '{ id name }')

// Create new user called `Sarah` and retrieve the `id`
prisma.mutation.createUser({ data: { name: 'Sarah' } }, '{ id }')

// Update name of a specific user and retrieve the `id`
prisma.mutation.updateUser({ where: { id: 'abc' }, data: { name: 'Sarah' } }, '{ id }')

// Delete a specific user and retrieve the `name`
prisma.mutation.deleteUser({ where: { id: 'abc' } }, '{ id }')
```


**内部机制**

prisma 的函数调用最终翻译为 `graphql-binding` 的方式

```js
prisma.exists.Post({
  id: 'abc',
  author: {
    name: 'Sarah'
  }
})
```

![](https://ws4.sinaimg.cn/large/006tNc79gy1foq4q30ngvj30jx05o0sr.jpg)