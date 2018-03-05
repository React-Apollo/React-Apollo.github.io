---
title: Prisma|Github oAuth登录操作
date: 2018-03-05 15:27:47
categories: 技术备忘
tags: [Prisma,oAuth]
---

之前有版本,经过Prisma 的版本变更.做修改.Prisma的改变还比较大,但是登录的原理是不变的

>OAuth 协议的认证和授权的过程如下：

 `1`. 用户打开我的应用，我想要通过GitHub获取改用户的基本信息

 `2`. 在转跳到GitHub的授权页面后，用户同意我获取他的基本信息

 `3`. 页面获得GitHub提供的授权码(githubCode)，使用该授权码向GitHub申请一个令牌

 `4`. GitHub对博客提供的授权码进行验证，验证无误后，发放一个令牌(githubToken)给博客端

 `5`. 应用使用令牌，向GitHub获取用户信息

 `6`. GitHub 确认令牌无误，返回给我基本的用户信息

 在本应用中,从github 中获取用户基本信息以后,在 prisma数据库中存储信息,并且返回给用于一个应用内的 token.后续应用内的操作通过这个 token换取用户信息进行操作
datamodel

```js
type User {
  id: ID! @unique

  createdAt: DateTime!
  updatedAt: DateTime!

  githubUserId: String! @unique

  name: String!
  bio: String!
  public_repos: Int!
  public_gists: Int!

  notes: [Note!]! @relation(name: "UserNote")
}

type Note {
  id: ID! @unique
  owner: User! @relation(name: "UserNote")

  text: String!
}
```

schemamodel

```js
type Query {
  me: User,
  note(id: ID!): Note
}

type Mutation {
  createNote(text: String!): Note!
  updateNote(id: ID!, text: String!): Note
  deleteNote(id: ID!): Note
  authenticate(githubCode: String!): AuthenticateUserPayload
}

type AuthenticateUserPayload {
  user: User!
  token: String!
}
```

`datamodel`定义了数据库要使用的 model, `schemamodel`定义了要提供给用户使用的 API接口. 所以编程就围绕 schemamodel 展开

重点关注 authenticate 这个 model. 通过参数 githubCode获得用户的 token

## 获取 token 的代码

### 从 github 获取信息的代码的两个工具函数

```
import * as fetch from 'isomorphic-fetch'

export interface GithubUser {
  id: string,
  name: string,
  bio: string,
  public_repos: number,
  public_gists: number
}
//获取 githubToken 的方法
export async function getGithubToken(githubCode: string): Promise<string> {
  const endpoint = 'https://github.com/login/oauth/access_token'

  const data = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      client_id: process.env.GITHUB_CLIENT_ID,
      client_secret: process.env.GITHUB_CLIENT_SECRET,
      code: githubCode,
    })
  })
    .then(response => response.json())

  if (data.error) {
    throw new Error(JSON.stringify(data.error))
  }

  return data.access_token
}

//获取 githubUser 的方法,获取的是 User的详细信息
export async function getGithubUser(githubToken: string): Promise<GithubUser> {
  const endpoint = `https://api.github.com/user?access_token=${githubToken}`
  const data = await fetch(endpoint)
    .then(response => response.json())

  if (data.error) {
    throw new Error(JSON.stringify(data.error))
  }

  return data
}

```



### 从 prisma 获取用户信息的工具函数
在其他操作需要用户信息时,可以从 http 请求只能获取用户 token,换取用户信息,


```js
import * as jwt from 'jsonwebtoken'
import { Prisma } from 'prisma-binding'
//在上下文中提供可以操作的 prisma 数据库句柄
export interface Context {
  db: Prisma
  request: any
}

export interface User {
  id: string
  name: string
  bio: string
  public_repos: string
  public_gists: string
}

export function getUserId(ctx: Context) {
  //从 http request 头部获得 token
  const Authorization = ctx.request.get('Authorization')
  if (Authorization) {
    const token = Authorization.replace('Bearer ', '')
    const { userId } = jwt.verify(token, process.env.JWT_SECRET!) as {
      userId: string
    }
    return userId
  }

  throw new AuthError()
}

export class AuthError extends Error {
  constructor() {
    super('Not authorized')
  }
}

```

### auth的 resolvers

```js
//Context是可以操作 prisma 数据库的句柄
import { Context, User } from '../../utils'

import { getGithubToken, getGithubUser, GithubUser } from '../../github'
import * as jwt from 'jsonwebtoken'

// Helpers -------------------------------------------------------------------

async function getPrismaUser(ctx: Context, githubUserId: string): Promise<User> {
  return await ctx.db.query.user({ where: { githubUserId } })
}

async function createPrismaUser(ctx, githubUser: GithubUser): Promise<User> {
  const user = await ctx.db.mutation.createUser({
    data: {
      githubUserId: githubUser.id,
      name: githubUser.name,
      bio: githubUser.bio,
      public_repos: githubUser.public_repos,
      public_gists: githubUser.public_gists,
      notes: [],
    },
  })
  return user
}

// Resolvers -----------------------------------------------------------------

export const auth = {
  authenticate: async (parent, { githubCode }, ctx: Context, info) => {
    const githubToken = await getGithubToken(githubCode)
    const githubUser = await getGithubUser(githubToken)
    //在 prisma 中查找用户,如果不存在就创建一个,然后返回一个 token 给用户
    let user = await getPrismaUser(ctx, githubUser.id)

    if (!user) {
      user = await createPrismaUser(ctx, githubUser)
    }

    return {
      token: jwt.sign({ userId: user.id }, process.env.JWT_SECRET),
      user,
    }
  },
}

// ---------------------------------------------------------------------------

```

### 执行其他操作时需要用户信息时的操作
下面操作由于,已经在 schemamodel 中定义了 user和 note 的关联关系, 只需要在 owner中关联 userID就可以了,其他信息可以灵活查询获取.

```js
mport { Context, getUserId, AuthError } from '../../utils'

export const notes = {
    async createNote(_, { text }, ctx: Context, info) {
        const userId = getUserId(ctx)
        return await ctx.db.mutation.createNote({ data: {
            owner: { connect: { id: userId } },
            text
        }})
    },
    async updateNote(_, { id, text }, ctx: Context, info) {
        const userId = getUserId(ctx)
        //检查这条消息是不是该用户创建的,是的话才能执行更新操作
        const hasPermission = await ctx.db.exists.Note({
            id,
            owner: { id: userId }
        })

        if (!hasPermission) {
            throw new AuthError()
        }

        return await ctx.db.mutation.updateNote({
            where: { id },
            data: { text }
        })
    },
    async deleteNote(_, { id }, ctx: Context, info) {
        const userId = getUserId(ctx)
        //检查这条消息是不是该用户创建的,是的话才能执行删除操作
        const hasPermission = await ctx.db.exists.Note({
            id,
            owner: { id: userId }
        })

        if (!hasPermission) {
            throw new AuthError()
        }
        return await ctx.db.mutation.deleteNote({ 
            where: { id }
        })
    }
}
```






