---
title: 构建基于MongoDB的 graphql 服务器(二)。
date: 2018-01-22 11:40:28
categories: 技术备忘
tags: [MongoDB,graphql]
---

#构建基于MongoDB的 graphql 服务器(二)

**项目起因**：
想包装一下cnode的api,可以使用graphql的mutate方法实现收藏cnode帖子功能，在resolvers中对api包装，用query就可以，因为具体的数据获取并没有使用Graphql的功能。  只不过套用了其中的模式。 但是定义好了mutate或者query在后面比较好理解。这里可以用了，但是不是太规范。
项目版本由此 衍生而来 
>graphql-mongodb-example
作者是："author": "Nicola Marcacci Rossi <nicolamr@gmail.com> (http://nmr.io)"
>这个版本在express-server中对es7的支持很好，语法检查也很完备
所以可以作为很好的初始版本。 整理好了之后，考虑向作者提出提交申请。

还有几个类似的服务器也在文件夹中，需要修改index.js的文件名



```javascript
import {MongoClient, ObjectId} from 'mongodb'
import express from 'express'
import bodyParser from 'body-parser'
import {graphqlExpress, graphiqlExpress} from 'graphql-server-express'
import {makeExecutableSchema} from 'graphql-tools'
import cors from 'cors'
import fetch from 'node-fetch'
require('es6-promise').polyfill()
require('isomorphic-fetch')
const URL = 'http://localhost'
const PORT = 3001
const MONGO_URL = 'mongodb://php-smarter:<password,去掉尖括号>@ds239097.mlab.com:39097/recompose'
const api = 'https://cnodejs.org/api/v1/topic_collect/collect'
// const request = require('superagent');

export const start = async () => {
  try {
    const typeDefs = [`
    type collectTopic {
      topic_id: String
      accesstoken: String
      success: Boolean
      }
    type Query {
      getCollectionTopic(topic_id: String!, accesstoken: String!): collectTopic,
      createCollectionTopic(topic_id: String!, accesstoken: String!): collectTopic
    },
    schema {
      query: Query
    }
  `]

 const resolvers = {
     Query: {

       createCollectionTopic: async (parent, args, context) => {
      const {accesstoken, topic_id} = args
      const body = {accesstoken: accesstoken, topic_id: topic_id}
      const ress = await fetch(api, {
        method: 'POST',
        body: JSON.stringify(body),
        headers: { 'Content-Type': 'application/json' }
      })
      .then(res => res.json())
      .then(json => json)
       console.log(ress)
       const success = {'success': ress.success}
      return success  
      }
     }

   }
    const schema = makeExecutableSchema({
      typeDefs,
      resolvers
    })

    const app = express()

    app.use(cors())

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

