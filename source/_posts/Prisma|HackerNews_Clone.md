---
title: Prisma|HackerNews_clone
date: 2018-01-28 08:17:07
categories: 技术备忘
tags: [Prisma]
---
> from [`howtographql.com`](https://www.howtographql.com/graphql-js/1-getting-started/) 

## API需求:
- `Retrieve a list` (feed) of link elements
- Allow users to `signup up` with their name, email and password
- Users who signed up should be able to `login` again with their email and password
- Allow authenticated users to `post` new link elements
- Allow authenticated users to `upvote` an existing link element
- Send `realtime updates` to subscribed clients when a new link element is created
- Send `realtime updates` to subscribed clients when an existing link element is upvoted

## 定义 应用 schema
`这一步非常好,根据应用的需求首先定义需要实现的 query,mutation,subscribe,然后围绕这个schema 展开工作`,目前我们不关注`User`,`Link`,`Vote`的实现细节

```
type Query {
  # Retrieve a list ("feed") of link elements
  feed(filter: String, skip: Int, first: Int): [Link!]!
}

type Mutation {
  # Allow users to signup up with their name, email and password
  signup(name: String!, email: String!, password: String!): AuthPayload!
  # Users who signed up should be able to login again with their email and password
  login(email: String!, password: String!): AuthPayload!
  # Allow authenticated users to post new link elements
  post(url: String!, description: String!): Link
  # Allow authenticated users to upvote an existing link element
  vote(linkId: ID!): Vote
}

type Subscription {
  # Send realtime updates to subscribed clients when a new link element is created
  newLink: LinkSubscriptionPayload
  # Send realtime updates to subscribed clients when an existing link element is upvoted
  newVote: VoteSubscriptionPayload
}

type AuthPayload {
  token: String
  user: User
}
```

接下来就是逐渐实现这些操作.每一步实现的流程实际是基本类似的-这也就是**schema-driven-development**
1. 调整 data model
2. 调整之后,部署服务
3. 用新的根字段扩展应用的 schema
4. 实现 resolver, 通过代理执行对应的 Prisma resolver

## 初始化文件结构

```js
.
├── package.json
├── src
│   ├── index.js
│   ├── schema.graphql
│   └── generated
│       └── prisma.graphql
└── database
    ├── prisma.yml
    └── datamodel.graphql
```

- `src`包含应用的实现代码和`应用schema(application schema)`,Prisma根据 dataModel生成的 `Prisma schema`
- `database` 包含初始化配置文件 prisma.yml和应用的 data model

 `src/schema.graphql(Apllication schema)`定义了暴露给 client 端的 graphql API. 

`src/generated/prisma.graphql(Prisma schema)`定义了对数据库操作的 CRUD API. 对于在 `data model` 中的每个类型,  Prisma会生成读写数据库节点的操作

`data model`并不是实际的 Graphql schema,缺少 root type. data model 用于生成实际执行的 schema.

## 理解初始化步骤

有两个依赖包:
- `graphql-yoga`: GraphQL Server 需要的文件,实际是 express 服务器
- `prisma-binding`: 可以允许绑定应用 schema 的 resolvers到自动生成的 Prisma database服务. 

```
const server = new GraphQLServer({
  typeDefs: './src/schema.graphql',
  resolvers,
  context: req => ({
    ...req,
    db: new Prisma({
      typeDefs: 'src/generated/database.graphql',
      endpoint: 'http://localhost:60000/hackernews-node/dev',
      secret: 'mysecret123',
    }),
  }),
})
```

## 查询

### 在 data model 中定义 `Link` type

```
type Link {
  id: ID! @unique
  description: String!
  url: String!
}
```

yarn prisma deploy 之后

会自动生成prisma.graphql

```
type Query {
  links(where: LinkWhereInput, orderBy: LinkOrderByInput, skip: Int, after: String, before: String, first: Int, last: Int): [Link]!
  link(where: LinkWhereUniqueInput!): Link
}

type Mutation {
  createLink(data: LinkCreateInput!): Link!
  updateLink(data: LinkUpdateInput!, where: LinkWhereUniqueInput!): Link
  deleteLink(where: LinkWhereUniqueInput!): Link
  updateManyLinks(data: LinkUpdateInput!, where: LinkWhereInput!): BatchPayload!
  deleteManyLinks(where: LinkWhereInput!): BatchPayload!
}
```


### 对 应用的 schema 做出调整

定义`feed`查询

```
# import Link from "./generated/prisma.graphql"

type Query {
  feed(filter: String, skip: Int, first: Int): [Link!]!
}
```

### 实现 `feed`的 resolver

每个`Query`,`Mutation`都由 resolver 支撑. 相应的定义为 `Query.js`,`Mutation.js`,`Subscription.js`.

```
function feed(parent, args, context, info) {
  const { filter, first, skip } = args // destructure input arguments
  const where = filter
    ? { OR: [{ url_contains: filter }, { description_contains: filter }] }
    : {}

  return context.db.query.links({ first, skip, where }, info)
}

module.exports = {
  feed,
}
```

resolver 函数接收四个参数,
1. `parent`:包含 resolver 链的初始值
2. `args`:包含查询参数的对象.
3. `context`:包含定制的数据,可以在 resolver 链中传递.例如每个 resolver 都可以读写
4. `info`包含了 AST信息

打开 `index.js`替换下面的`resolver`对象:

```js
const resolvers = {
  Query,
}
``` 

导入我们自己定义的`Query`对象

```js
const Query=require('./resolvers/Query')
```

### 测试 API

在项目的根目录执行
```
yarn dev
```

打开 graphiQL, 输入

```js
mutation {
  createLink(data: {
    url: "https://www.graph.cool",
    description: "A GraphQL Database"
  }) {
    id
  }
}
```

## Mutations

### Mutation for posting new links

打开 `src/schema.graphql`添加如下代码

```js
type Mutation {
  post(url: String!, description: String!): Link!
}
```

在`src/resolvers`创建新的`Mutation.js`,添加代码:

```js
function post(parent, args, context, info) {
  const { url, description } = args
  return context.db.mutation.createLink({ data: { url, description } }, info)
}

module.exports = {
  post,
}
```

在`index.js`中添加新的`mutation`声明

```js
const Mutation = require('./resolvers/Mutation')

const resolvers = {
  Query,
  Mutation,
}
```

测试一下

```js
mutation {
  post(url: "https://www.howtographql.com", description: "Fullstack tutorial website for GraphQL") {
    id
  }
}
```

## Signup&Login

### 为用户提供登录功能

#### Signup
注册的实现步骤:
1. 服务器收到新用户的`email`,`password`(还有`name`)
2. 服务器在数据库创建新用户,并储存`name`,`email`和 hash过的密码
3. 服务器创建一个认证 token(JWT)
4. 服务器把 token返回给用户

#### Login
1. 服务器收到`login` mutation
2. 服务器比较`password`的一致性
3. 如果密码一致, 服务器创建一个 token
4. 服务器把 token 返回给用户

### 实现注册流程

创建secret

```js
const APP_SECRET = 'GraphQL-is-aw3some'

module.exports = {
  APP_SECRET
}

```

在应用的 schema 中添加 `signup`  `Mutation`

```js
type Mutation {
  post(url: String!, description: String!): Link!
  signup(email: String!, password: String!, name: String!): AuthPayload
}
```

`src/schema.graphql`
```
type AuthPayload {
  token: String
  user: User
}
```

`database/datamodel.graphql`

```
type User {
  id: ID! @unique
  name: String!
  email: String! @unique
  password: String!
}

```

部署以后会生成

```js
type Query {
  users(where: UserWhereInput, orderBy: UserOrderByInput, skip: Int, after: String, before: String, first: Int, last: Int): [User]!
  user(where: UserWhereUniqueInput!): User
}

type Mutation {
  createUser(data: UserCreateInput!): User!
  updateUser(data: UserUpdateInput!, where: UserWhereUniqueInput!): User
  deleteUser(where: UserWhereUniqueInput!): User
  upsertUser(where: UserWhereUniqueInput!, create: UserCreateInput!, update: UserUpdateInput!): User!
  updateManyUsers(data: UserUpdateInput!, where: UserWhereInput!): BatchPayload!
  deleteManyUsers(where: UserWhereInput!): BatchPayload!
}
```


打开应用 schema `src/schema.graphql`添加如下的类型

```
type User{
   id: ID!
   name:String!
   email:String!
}
```

这里的定义和 Prisma schema 里的定义类似,但是没有`password`,也就是不允许用户查询 password

接下来需要`signup` mutation

```js
async function signup(parent, args, context, info) {
  const password = await bcrypt.hash(args.password, 10)
  const user = await context.db.mutation.createUser({
    data: { ...args, password },
  })

  const token = jwt.sign({ userId: user.id }, APP_SECRET)

  return {
    token,
    user,
  }
}
```


在`signup` resolver 中, 首先创建密码的加密版本, 接下来, 使用`Prisma`的实例,创建新的`User`节点.最后返回包含`AuthPayload`包含创建的 token 和新的 user 对象

### 实现`login` mutation

接下来,实现`login` mutation. 


`src/schema.graphql`中添加Mutation 类型

```js
type Mutation {
  post(url: String!, description: String!): Link!
  signup(email: String!, password: String!, name: String!): AuthPayload
  login(email: String!, password: String!): AuthPayload
}
```

打开 `src/resolvers/Mutation.js`添加如下函数

```js
async function login(parent, args, context, info) {
  const user = await context.db.query.user({ where: { email: args.email } })
  if (!user) {
    throw new Error(`Could not find user with email: ${args.email}`)
  }

  const valid = await bcrypt.compare(args.password, user.password)
  if (!valid) {
    throw new Error('Invalid password')
  }

  const token = jwt.sign({ userId: user.id }, APP_SECRET)

  return {
    token,
    user,
  }
}
```

首先使用 email 查询是否存在, 然后比较密码是否一致.  完成后,返回一个 token 给用户

### 应用 Authentication

#### 创建`User`和`Link`的关联

在需求中,我们提出只有通过认证的用户才可以创建新的 `Link`元素.

打开 `database/datamodel.js` 改变`User`和`Link`类型

```js
type Link {
  id: ID! @unique
  description: String!
  url: String!
  postedBy: User
}

type User {
  id: ID! @unique
  name: String!
  email: String! @unique
  password: String!
  links: [Link!]!
}
```

可以执行如下的操作

```
mutation {
  createLink(data: {
    url: "https://www.graphql.org",
    description: "Official GraphQL Website",
    postedBy: {
      connect: {
        email: "johndoe@graph.cool"
      }
    }
  }) {
    id
  }
}
```


打开 `src/resolvers/Mutation.js`改变`post`

```js
function post(parent, { url, description }, context, info) {
  const userId = getUserId(context)
  return context.db.mutation.createLink(
    { data: { url, description, postedBy: { connect: { id: userId } } } },
    info,
  )
}
```


和之前的版本不同的地方是,首先获取到用户的 id, 然后传递给`createLink`-mutation 作为`connect`的参数. 

现在我们需要一个工具函数 `getUserId`,

`src/utils.js`

```js
function getUserId(context) {
  const Authorization = context.request.get('Authorization')
  if (Authorization) {
    const token = Authorization.replace('Bearer ', '')
    const { userId } = jwt.verify(token, APP_SECRET)
    return userId
  }

  throw new Error('Not authenticated')
}
```


`context`参数有一个`request`属性,代表着携带 query 或者 mutation的 HTTP 请求.  重要的是,它提供了访问头 .token就在头部中

#### 认证一个用户

1. 在 playground中, 发送`signup`或者`login` mutation,从 graphql server 中获取到 `token`.
2. 在`PlayGround`中设置Header
3. 发送`post` mutation,创建新的`Link` 元素


```js
mutation {
  login(
    email: "johndoe@graph.cool"
    password: "graphql"
  ) {
    token
  }
}
```



设置好以后,执行

```js
mutation {
  post(
    url: "https://www.graphqlweekly.com"
    description: "Weekly GraphQL Newsletter"
  ) {
    id
  }
}
```


---
投票部分
---



## Subscriptions

###  实现 GraphQL订阅

打开`src/schema.graphql`,添加`Subscription`

```js
type Subscription {
  newLink: LinkSubscriptionPayload
  newVote: VoteSubscriptionPayload
}
```


在`src/resolvers`创建一个新的文件, `SubScription.js`添加如下代码:

```js
const newLink = {
  subscribe: (parent, args, ctx, info) => {
    return ctx.db.subscription.link(
      { },
      info,
    )
  },
}

const newVote = {
  subscribe: (parent, args, ctx, info) => {
    return ctx.db.subscription.vote(
      { },
      info,
    )
  },
}

module.exports = {
  newLink,
  newVote,
}
```


现在的`src/inde.js`文件

```js
const { GraphQLServer } = require('graphql-yoga')
const { Prisma } = require('prisma-binding')
const Query = require('./resolvers/Query')
const Mutation = require('./resolvers/Mutation')
const Subscription = require('./resolvers/Subscription')

const resolvers = {
  Query,
  Mutation,
  Subscription
}
```



