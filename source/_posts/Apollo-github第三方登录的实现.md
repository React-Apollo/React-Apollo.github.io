---
title: Apollo-github第三方登录的实现
date: 2018-01-21 22:30:28
categories: 技术备忘
tags: [Apollo-client,graphql]
---

# graphcool-github第三方登录的实现 

>OAuth 协议的认证和授权的过程如下：


1.用户打开我的博客后，我想要通过GitHub获取改用户的基本信息
2.在转跳到GitHub的授权页面后，用户同意我获取他的基本信息
3.博客获得GitHub提供的授权码，使用该授权码向GitHub申请一个令牌
4.GitHub对博客提供的授权码进行验证，验证无误后，发放一个   令牌给博客端
5.博客端使用令牌，向GitHub获取用户信息
6.GitHub 确认令牌无误，返回给我基本的用户信息

基本的流程就是如此。在Graphcool的官方路程中跑不通这个过程，好像是fetch的异步操作有问题。所我用了单独的graphql服务器来实现，官方流程中需要把数据存到graphcool的库中，这一步没有做。 

### 获得授权码
这要用一个登陆页面，有github的脚本，和你我申请的ID。共同去服务端获得一个githubUserCode,这个就是要使用的查询参数。

html网页通过http-server本地服务器加载，主要的是这个服务的的端口`要和github申请时的回调地址和端口一致`。光放文档是使用的是python的http服务，我没用，端口可能是8000.用http-server时端口是8080，和文档描述不一致的时候，要知道为什么。
官方的文件为template仓库 
`html文件`
```html
<html>

<body>
  <script>
    // Github client id
    const client_id = '842e83a0329b156b0a5b'

    // Will extract code from current url
    const githubCode = window.location.search.substring(1).split('&')[0].split('code=')[1]
    if (githubCode) {
      // call Graphcool authenticateGithubUser mutation
      console.log(githubCode)
    }

    function getgithubCode() {
      window.location = `https://github.com/login/oauth/authorize?client_id=${client_id}&scope=user`
    }
  </script>
  <button onclick="getgithubCode();">Authenticate with Github</button>
</body>

</html>

```
这里是一个静态的html页面，如果是webapp或者APP的话，这里点击后，从github网站请求到githubUserCode，以后可以执行换取用户信息的工作了。这里为了方便，通过console.log的方式在终端中打印出gitHubUser的值，然后我在graqhiql界面执行一个查询操作，如下。

```javascript
import express from 'express'
import bodyParser from 'body-parser'
import {graphqlExpress, graphiqlExpress} from 'graphql-server-express'
import {makeExecutableSchema} from 'graphql-tools'
import cors from 'cors'
require('es6-promise').polyfill();
require('isomorphic-fetch');
import fetch from 'node-fetch';

const URL = 'http://localhost'
const PORT = 3001
export const start = async () => {
  try {

    const typeDefs = [`
    type AuthenticateUserPayload {
      id: ID!
      token: String!
    }
    
    type Query {
      getGithubToken(githubCode: String!): AuthenticateUserPayload
    }
    schema {
      query: Query
    }
    `];

  
   const resolvers ={
     Query :{
    /*test start area*/  
     getGithubToken:async (parent,args,context)=>{
       console.log(args);
      const endpoint = 'https://github.com/login/oauth/access_token'
      const {githubCode} =args;
      const client_id= '842e83a0329b156b0a5b'
      const client_secret = '0a25a9f3c5cb3d47eece0b54e58163a188834bf9'
      const data = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          client_id,
          client_secret,
          code: githubCode,
        })
      })
        .then(response => response.json())
    
      if (data.error) {
        throw new Error(JSON.stringify(data.error))
      }
      console.log("data,",data);
      const  res=await getGithubUser(data.access_token)
      console.log(res);
      return {token:data.access_token,id:res.id};
    }
    /*test end area*/   
     }

   }

   const getGithubUser=async (githubToken)=>{
    const endpoint = `https://api.github.com/user?access_token=${githubToken}` 
    const data = await fetch(endpoint).then(response => response.json())
    if (data.error) {
      throw new Error(JSON.stringify(data.error))
    }
  
    return data
  }
   
   const schema = makeExecutableSchema({
      typeDefs,
      resolvers
    })

    const app = express()

    //app.use(cors())

    app.use('/graphql', bodyParser.json(), graphqlExpress({schema: schema}))

    const homePath = '/graphiql'

    app.use(homePath, graphiqlExpress({
      endpointURL: '/graphql'
    }))

    app.listen(PORT, () => {
      console.log(`Visit ${URL}:${PORT}${homePath}`)
    })

  } catch (e) {
    console.log(e)
  }

}
```

在这个服务器的resolver中post请求发送githubUser信息到github.
实际的代码是很简单的。 注意异步操作的问题，在这个问题上绕了很久，才摸索出上面的方法。

###  ResT-Wrapper中的实现
在Graphcool rest-wrapper实例代码中也实现了这个操作。 graphcool的起始配置很复杂，但是实际使用时很方便的。  
`rest-wrapper`的库提交到`bitbucket`上.
文件目录 src/github/  文件结构已经重新整理过
resolver'的代码如下：建了两个数据模型但是没有使用
```
import {fromEvent, FunctionEvent} from 'graphcool-lib'
import {GraphQLClient} from 'graphql-request'
import * as fetch from 'isomorphic-fetch'

interface User {
  id : string
}

interface GithubUser {
  id : string
  html_url: string
  gists_url: string
  avatar_url: string
}

interface EventData {
  githubCode : string
}

// read Github credentials from environment variables

export default async(event : FunctionEvent < EventData >) => {
  console.log(event)

  // if (!process.env.GITHUB_CLIENT_ID || !process.env.GITHUB_CLIENT_SECRET) {
  // console.log('Please provide a valid client id and secret!')   return { error:
  // 'Github Authentication not configured correctly.' } }

  try {
    

    const {githubCode} = event.data

    // get github token
    const githubToken : string = await getGithubToken(githubCode)

    // call github API to obtain user data
    const githubUser: any= await getGithubUser(githubToken)

    // get graphcool user by github id
    
    return {
      data: {
        id: githubUser.id.toString(),
        token: githubToken,
        html_url: githubUser.html_url,
        avatar_url: githubUser.avatar_url,
        gists_url: githubUser.gists_url
      }
    }
  } catch (e) {
    console.log(e)
    return {error: 'An unexpected error occured during authentication.'}
  }
}

async function getGithubToken(githubCode) {
  const client_id = '842e83a0329b156b0a5b'
  const client_secret = '0a25a9f3c5cb3d47eece0b54e58163a188834bf9'

  const endpoint = 'https://github.com/login/oauth/access_token'

  const data = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({client_id, client_secret, code: githubCode})
  }).then(response => response.json())

  if (data.error) {
    throw new Error(JSON.stringify(data.error))
  }

  return data.access_token
  //const  res=await getGithubUser(data.access_token)
  //console.log(res);
  //return {token:data.access_token,id:res.id};
}
async function getGithubUser(githubToken : string) : Promise < GithubUser > {
  const endpoint = `https://api.github.com/user?access_token=${githubToken}` 
  const data = await fetch(endpoint).then(response => response.json())if (data.error) {
    throw new Error(JSON.stringify(data.error))
  }

  return data
}
```

方法和流程其实是一样的。


如果在node.js下要想执行grapql操作，最好是使用graph-lib库来实现。
方法和客户端一样， 都是执行异步操作。

 

