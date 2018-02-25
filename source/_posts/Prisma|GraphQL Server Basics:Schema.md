---
title: Prisma|GraphQL Server Basics:Schema
date: 2018-02-25 10:28:43
categories: 技术备忘
tags: [Graphcool,Prisma]
---
>[`GraphQL Server Basics: The Schema`](https://blog.graph.cool/graphql-server-basics-the-schema-ac5e2950214e) 原文在这里


### 构建 GraphQL 服务器
第一步是设计 schema. 这里讲解 schema 的组成

#### GraphQL schema 定义了服务器的 API
`定义语言`: Schema Definition Language(SDL)

示例:

```js
type User{
   id:ID!
   name:String!
}
```

只有`User`,并不能给客户端提供任何的功能. 只是简单的定义了用户的模型. 为了添加功能, 需要在 root type 中添加字段:`Query`,`Mutation`,`Subscription`. 这些字段定义了 GraphQL API 的入口

示例代码: 

```js
query {
    user(id:"abc"){
      id 
      name
    }
}
```

对于这个查询,要想获取结果, 必须要定义`Query`类型

```js
type Query{
  user(id:ID!):User
}
```

因此`shcema 的 root type定义了 server 可以接受的 query,mutation的结构`


#### GraphQLSchema对象是 GraphQL Server 的核心

主要包括两个主要的组件:
- `①`schema 定义
- `②`实际实现的 resolvers 函数


针对上面的例子, `GraphQLSchema`对象是:

```js
//
const UserType = new GraphQLObjectType({
  name: 'User',
  fields: {
    id: { type: GraphQLID },
    name: { type: GraphQLString }
  }
})

const schema = new GraphQLSchema({
  query: new GraphQLObjectType({
    name: 'Query',
    fields: {
      user: {
        type: UserType,
        args: {
          id: { type: GraphQLID }
        }
      }
    }
  })
})
```

`SDL版的 schema 被翻译为 JS的形式`.这里还没有 resolvers,所以还实现不了具体的功能

### Resolvers负责具体实现 API

####  GraphQL Server 中的结构和行为
在 GraphQL Server 中结构和行为是明显分开的, 结构就是 `shcema`,行为实现的关键组件就是`resolver`函数.

下面这一点是非常重要的一句总结:

**`每个GraphQL schema的字段都有 resolver 支撑`**

在基础结构中, GraphQL Server 为每个字段都提供 `resolver` 函数.每个resolver 都知道怎么获取对应字段的数据.  因为**`GraphQL 查询的精髓:仅仅返回字段的集合(collection)`** GraphQL Server 要做的事情`**只是为查询中的每个字段调用 resolver 函数`**.   简单说: **`只是调用远程的函数`**.

#### resolver 函数的剖析

针对上面的user 字段:

```js
const UserType = new GraphQLObjectType({
  name: 'User',
  fields: {
    id: { type: GraphQLID },
    name: { type: GraphQLString }
  }
})

const schema = new GraphQLSchema({
  query: new GraphQLObjectType({
    name: 'Query',
    fields: {
      user: {
        type: UserType,
        args: {
          id: { type: GraphQLID }
        }
      }
    }
  })
})
```

假设有一个函数`fetchUserById`,被实际调用,返回一个 js 对象(有`id`,`name`字段), resolver 函数使得 schema 可以执行实际的功能了.

下面看看 resolver 函数中的四个参数:

- `root`:   resolver 中的root 是之前调用的结果
- `args`:   包含了查询的参数,这个例子中是`id`
- `context`:在 resolver 函数链中传递的对象, 每个 resolver 都可以访问(用于 resolver 之间通讯和共享信息)
- `info`:   查询或者 mutation 的 AST结构图. 


完整的查询 resolver 返回的字段:

`这就是实际的操作, 每个字段都是单独返回的`
```js
const UserType = new GraphQLObjectType({
  name: 'User',
  fields: {
    id: { 
      type: GraphQLID,
      resolve: (root, args, context, info) => {
        return root.id
      }
    },
    name: { 
      type: GraphQLString,
      resolve: (root, args, context, info) => {
        return root.name
      }
    }
  }
})
```


#### 执行查询

![](https://ws2.sinaimg.cn/large/006tNc79gy1foryswqfoxj31400n3wh2.jpg)

具体的步骤:

- `①` query到达服务器
- `②` 服务器调用 resolver 用于查询`user`的字段
- `③` 为type `User`的字段 `id`调用 resolver函数, root 为这个 resolver 提供参数,就是之前调用的返回值,  `root.id`.
- `④` 和`③`类似,只是返回`root.name` ,`③`和`④`是并行操作
- `⑤`操作结束, 最终的结果包装在`data` 字段中 


```js
{
  "data": {
    "user": {
      "id": "abc",
      "name": "Sarah"
    }
  }
}

```

这些琐碎的流程实际`GraphQL.js`已经为我们完成了

### 优化请求: DataLoader 模式
在客户端发送嵌套查询时, 很容易出现性能问题

例如:

```js
query {
  user(id: "abc") {
    name
    article(title: "GraphQL is great") {
      comments {
        text
        writtenBy {
          name
        }
      }
    }
  }
}
```

如果一篇文章有五条评论,我们要执行五次`writtenBy` resolver.`DataLoader`可以让你避免这个问题,简单说就是函数调用是批量进行的


### GraphQL.js VS. graphql-tools

#### GraphQL.js 为 graphql-tools提供了基础
GraphQL.js 是底层干活的, graphql-tools 提供了一个易于使用的应用层. 

##### GraphQL.js 的组成部分

- `parse`和`buildASTSchema`:给定一个 schema 的字符串,这两个函数会创建一个`GraphQLSchema`的实例:`const schema=buildASTSchema(parse(sdlString))`

- `validate`: validate确保 query符合 API的定义

- `execute`: 给定一个schema 实例和一个查询, `execute`负责调用字段的 resolver函数,根据 GraphQL 规范创建响应.

- `printSchema`: 接收 schema实例用 SDL 形式返回它的定义

GraphQL 中最重要的函数是`graphql`,接收`GraphQLSchema`实例和查询-然后调用验证和执行

```js
graphql(schema, query).then(result => console.log(result))
```


可以认为`graphql`的功能就是作为GraphQL engine.

####  graphql-tools  桥接接口和实现


在`GraphQL.js`的基础上, `graphql-tools`提供了一个重要的功能`addResolverFunctionToSchema`. 基于 SDL 创建 schema的问题就解决了.准确的讲应该是`makeEcecutableSchema`:

```js
const { makeExecutableSchema } = require('graphql-tools')

const typeDefs = `
type Query {
  user(id: ID!): User
}
type User {
  id: ID!
  name: String
}`

const resolvers = {
  Query: {
    user: (root, args, context, info) => {
      return fetchUserById(args.id)
    }
  },
}

const schema = makeExecutableSchema({
  typeDefs,
  resolvers
})
```

所以使用`graphql-tools`的最大好处是连接你的scehma 和 resolvers

#### 什么时候不要使用 graphql-tools?

graphql-tools 只是在`GraphQL.js`的基础是提供一个便于使用的抽象. 所以有的时候直接使用 graphql-tools 可能不太好

这是以牺牲灵活性为代价的. 如果你的服务器需要定制很多需求, 例如动态构建或者修改 scehma. 可能要返回去使用GraphQL.js

####  graphene.js 快速浏览

`graphene.js`是从 Python表兄那里获取的灵感.  底层仍然是 GraphQL.js, 但是不能声明式定义 schema.

`graphenes.js`使用了最新的 js 语法,  查询和 mutation可以以 js 的类形式表现.丰富了 graphql的 Ecosystem



### 结论

 GraqhQL.js 是实现功能的引擎.  

 

