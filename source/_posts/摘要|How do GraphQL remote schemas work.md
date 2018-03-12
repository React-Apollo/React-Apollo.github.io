---
title: 摘要|How do GraphQL remote schemas work?
date: 2018-03-10 22:16:54
categories: 技术备忘
tags: [Graphcool,Prisma]
---
>Understanding GraphQL schema stitching(part I)
>目的是使用已经有的 graphql API,通过我们自己的服务器暴露出来. 在配置阶段,我们只是简单的转发收到的GraphQL query 和 mutations. `负责转发这些操作的组件被称为 remote(executable)schema`.

Remote shcema 作为 schema stitching schema的基础工具. 下面讨论一下细节问题.

## 回忆一下 GraphQL schemas

schema由两个主要组件构成(这里的组件不是 react组件)

-  `schema definition`: 这部分通常用 schema definition language(SDL).本质上, schema 定义了 server能够接受的操作是什么, 需要报含`Query` type,可选的`Mutations`,`Subscription`. 可以用`typeDefs`定义
-  `Resolvers`: 这里是 shcema 真正进入到实际操作的地方, Resolvers实现了有由 schema 定义的 API 规范.

>当一个 schema 有了 definition和 resolver,被称为**executable schema**. 

下面是简单的实例,使用`graphql-tools` 的`makeEcecutableSchema`函数:

```js
const { makeExecutableSchema } = require('graphql-tools')

// SCHEMA DEFINITION
const typeDefs = `
type Query {
  user(id: ID!): User
}
type User {
  id: ID!
  name: String
}`

// RESOLVERS
const resolvers = {
  Query: {
    user: (root, args, context, info) => {
      return fetchUserById(args.id) //可以是数据库查询,或者是从其他的
      //REST API  获取数据
    }
  },
}

// (EXECUTABLE) SCHEMA
const schema = makeExecutableSchema({
  typeDefs,
  resolvers
})
```

`typeDefs`包含了 schema 定义, 由`Query`和简单的`User` type组成. `resolvers`是包含了如何实现`Query` type 中`user`字段实现的方案

`makeEcecutableSchema`: 从 SDL type 映射到对应的 resolver.  返回的实例可以用于直接的查询. 例如`graphql`函数

```js
... // other imports
const { graphql } = require('graphql')

const schema = ... // the schema from above
const query = `
  query {
    user(id: "abc") {
      id
      name
    }
  }
`

graphql(schema, query)
  .then(result => console.log(result))
```

`因为 grphql 函数可以根据 GraphQLSchema的实例来查询,所以也可以被认为是 GraphQL(execute) 引擎`


以上只是回顾. 现在看看如何根据已经存在的 graphql API 创建`GraphQLSchema`的可执行实例

##  Introspecting GraphQL APIS

GraphQL的有一个很趁手的属性, `introspection`. 可以发起一个 introspection query 来获取schema的定义.

```
query {
  __schema {
    types {
      name
      fields {
        name
      }
    }
  }
}
```

返回的是 json 格式的数据

```js
{
  "data": {
    "__schema": {
      "types": [
        {
          "name": "Query",
          "fields": [
            {
              "name": "user"
            }
          ]
        },
        {
          "name": "User",
          "fields": [
            {
              "name": "id"
            },
            {
              "name": "name"
            }
          ]
        },
        // ... some more metadata
      ]
    }
  }
}
```

返回的 schema和我们自己定义的 shcema 很像, 稍有差别,但是可以修改

## 创建一个 remote schema

![](https://ws2.sinaimg.cn/large/006tNc79gy1fp85rjmcwmj30nj0g7mxc.jpg)
![](https://ws2.sinaimg.cn/large/006tNc79gy1fp85rwqgb9j30ns07o74f.jpg)

`makeRemoteExecutableSchema`接收两个参数
- 一个 shcema 定义(这里通过 introspection 获取). 最佳实践是直接定义为 `.grpahql`文件
- Link连接被代理的 GraphQL API. 本质上, Link 是转发 query 和 mutation 的组件.  

没有办法获取到 remote的 resolver.但是可以创建新的 resolver,来转发操作到内部的 GraphQL API.

看看实际的代码, 基于一个 API,用于`User`模型. 

```js
const fetch = require('node-fetch')
const { makeRemoteExecutableSchema, introspectSchema } = require('graphql-tools')
const { GraphQLServer } = require('graphql-yoga')
const { createHttpLink } = require('apollo-link-http')

const { DATABASE_SERVICE_ID } = require('./services')

async function run() {
  // 1. Create Apollo Link that's connected to the underlying GraphQL API
  const makeDatabaseServiceLink = () => createHttpLink({
    uri: `https://api.graph.cool/simple/v1/${DATABASE_SERVICE_ID}`,
    fetch
  })

  // 2. Retrieve schema definition of the underlying GraphQL API 
  const databaseServiceSchemaDefinition = await introspectSchema(makeDatabaseServiceLink())

  // 3. Create the executable schema based on schema definition and Apollo Link
  const databaseServiceExecutableSchema = makeRemoteExecutableSchema({
    schema: databaseServiceSchemaDefinition,
    link: makeDatabaseServiceLink()
  })

  // 4. Create and start proxy server based on the executable schema
  const server = new GraphQLServer({ schema: databaseServiceExecutableSchema })
  server.start(() => console.log('Server is running on http://localhost:4000'))
}

run()
```

用于`User` type 的 CRUD API

```js
type User @model {
  id: ID! @isUnique
  name: String!
}

type Query {
  allUsers: [User!]!
  User(id: ID!): User
}

type Mutation  {
  createUser(name: String!): User
  updateUser(id: ID!, name: String): User
  deleteUser(id: ID!): User
}
```


### 底层的 Remote schemas

#### Inspecting GraphQL schemas

![](https://ws2.sinaimg.cn/large/006tNc79gy1fp86a7tybjj30f7074wem.jpg)

篮框显示`Query` type和他的属性. 有字段`allUsers`,但是 没有 resolver,所以这不是可执行的. 

![](https://ws2.sinaimg.cn/large/006tNc79gy1fp86rsnndcj30ef07fweo.jpg)

现在有 `resolver`了. 

继续看看 `resolver `的实现,(这是由 makeRemoteExecuteableSchema 自动生成的).

```js
function (root, args, context, info) {
  return __awaiter(_this, void 0, void 0, function () {
    var fragments, document, result;
    return __generator(this, function (_a) {
      switch (_a.label) {
        case 0:
          fragments = Object.keys(info.fragments).map(function (fragment) { return info.fragments[fragment]; });
          document = {
            kind: graphql_1.Kind.DOCUMENT,
            definitions: [info.operation].concat(fragments),
          };
          return [4 /*yield*/, fetcher({
            query: graphql_2.print(document),
            variables: info.variableValues,
            context: { graphqlContext: context },
          })];
        case 1:
          result = _a.sent();
          return [2 /*return*/, errors_1.checkResultAndHandleErrors(result, info)];
      }
    });
  });
}
```

12-16行代码 函数`fetcher`用三个参数调用,`query`,`variables`,`context`,




