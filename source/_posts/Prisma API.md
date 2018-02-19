---
title: Prisma API
date: 2018-02-19 20:00:40
categories: 技术备忘
tags: [Graphcool,Prisma]
---
{{TOC}}

### Prisma的 API 是什么?
Prisma服务暴露的 GraphQL API是基于部署的 data model 自动生成的. Prisma API 为 data model 中的 type 定义了 CRUD 操作,
### 探索 Prisma API
`Graphql Playground`是探索 Prisma API 的最好工具. 使用`prisma playground`可以打开这个工具

## Concepts
### data model 和 Prisma database schema
### 高级概念

```js
type Post {
  id: ID! @unique
  title: String!
  published: Boolean @default(value: "false")
}
```

**Retrive a single node by its `email`**

```js
query {
  post(where: {
    email: "hello@graph.cool"
  }) {
    id
  }
}
```

**update single node `title`**

```js
mutation {
  updatePost(
    where: {
      id: "ohco0iewee6eizidohwigheif"
    }
    data: {//⛔️这里注意这个 data
      title: "GraphQL is awesome"
    }
  ) {
    id
  }
}
```

**立刻更新多个 node 的`published`**

```js
mutation {
  updatePost(
    where: {
      id_in: ["ohco0iewee6eizidohwigheif", "phah4ooqueengij0kan4sahlo", "chae8keizohmiothuewuvahpa"]
    }
    data: {
      published: true
    }
  ) {
    count
  }
}
```

 
### connections
connections基于的是 Relay connection model.除了提供分页信息,还提供诸如 aggregation 等信息

```js
query {
  postsConnection {
    # `aggregate` allows to perform common aggregation operations
    aggregate {
      count
    }
    edges {
      # each `node` refers to a single `Post` element
      node {
        title
      }
    }
  }
}
```

### 认证
token:在发送 query 和 mutation 时要在 http  header 中 添加 token

### Error handling
有两种错误:
- **Application error**: 表示请求无效
- **Internal server errors**: 通常意味着 Prisma的服务有问题. 查看服务日志可以提供更多的信息.

##  Queries
Prisma 提供两种查询
- **对象查询**: 获取特定 type的单个或多个 node
- **Connection 查询**:提供高级特性
- **Hierarchical 查询**: 跨关联获取数据
- **Query 参数**: 允许过滤,排序, 分页等操作

Prisma API 都是基于 data model. 

```js
type Post {
  id: ID! @unique
  title: String!
  published: Boolean!
  author: User!
}

type User {
  id: ID! @unique
  age: Int
  email: String! @unique
  name: String!
  accessRole: AccessRole
  posts: [Post!]!
}

enum AccessRole {
  USER
  ADMIN
}
```

### 对象查询:

```js
query {
  posts {
    id
    title
  }
}
```

使用 `where` 参数

```js
query {
  post(where: {
    id: "cixnen24p33lo0143bexvr52n"
  }) {
    id
    title
    published
  }
}
```

获取 大于18岁的用户:

```js
query {
  users(where: {
    age_gt: 18
  }) {
    id
    name
  }
}
```

也可以跨关系查询, 获取`Post`作者年龄超过18岁的节点

```js
query {
  posts(where: {
    author: {
      age_gt: 18
    }
  }) {
    id
    title
    author {
      name
      age
    }
  }
}
```

### connections queries

在特殊案例中要使用高级特性, 可以用 connection queries. 他们是 Relay connection 的扩展. Relay connections 的核心概念是提供 data graph 中edge 的 meta-information.例如 例如 edge 不仅提供对象的信息,还提供关联的`cursor`,可以借此实现强有力的分页功能.

我们使用`postsConnection`query 来获取所有的`Posts` nodes.同时也请求了每个 edge的`cursor`.

```js
# Fetch all posts
query {
  postsConnection {
    edges {
      cursor
      node {
        id
        title
      }
    }
  }
}
```

connection 查询也提供聚合方式

```js
# Count all posts with a title containing 'GraphQL'
query {
  postsConnection(where: {
    title_contains: "GraphQL"
  }) {
    aggregate {
      count
    }
  }
}
```


### 跨关联查询数据
datamodel 中可用的每个 relation 都在两个 model 中添加新的字段

如下,我们活儿特定的 User, 所有与之有关的 Post nodes,

```js
query {
  user(where: {
    id: "cixnekqnu2ify0134ekw4pox8"
  }) {
    id
    name
    posts {
      id
      published
    }
  }
}
```

### Query 参数
- 使用`orderBy`对数据排序
- 使用`where`对查询的标量或者过滤器进行筛选
- 使用`first`,`last`,`after`和`skip`提供分页

#### 通过字段进行排序
`orderBy:<field>_ASC`,`orderBy:<field>_DESC`

根据标题升序排列所有的 Post node

```js
query {
  posts(orderBy: title_ASC) {
    id
    title
    published
  }
}
```

#### Filtering by value

查询所有未出版的 Post:

```js
query {
  posts(where: {
    published: false
  }) {
    id
    title
    published
  }
}
```

查询含有列表标题之一的所有 Post:

```js
query {
  posts(where: {
    title_in: ["My biggest Adventure", "My latest Hobbies"]
  }) {
    id
    title
    published
  }
}
```

#### Relation filters

查询用户角色作者的所有 Post

```js
query {
  posts(where: {
    author: {
      accessRole: USER
    }
  }) {
    title
  }
}
```


#### 组合多个 过滤器
**使用 OR或者AND**
查询所有的已经出版的`Post` nodes, 并且标题在列表中

```js
query {
  posts(where: {
    AND: [{
      title_in: ["My biggest Adventure", "My latest Hobbies"]
    }, {
      published: true
    }]
  }) {
    id
    title
    published
  }
}
```






