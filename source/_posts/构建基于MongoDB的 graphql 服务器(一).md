---
title: 构建基于MongoDB的 graphql 服务器(一)。
date: 2018-01-22 11:18:28
categories: 技术备忘
tags: [MongoDB,graphql]
---

#构建基于MongoDB的 graphql 服务器(一)

**项目起因**：本来想在后端使用graphcool服务器，在后端定义好了schema之后，其他的工作就由graphcool 自动生成了CURD的各种方法，很好用，因为graphql的自省功能，可以在graphiql查询时根据定义好的schma给你提供很好的提示
但是如果要批量导入数据，就比较麻烦。所以尝试使用mongodb+graphql的方法自建一个服务器，根据下面版本建立了一个服务器。
项目版本由此 衍生而来 
>graphql-mongodb-example
作者是："author": "Nicola Marcacci Rossi <nicolamr@gmail.com> (http://nmr.io)"
>这个版本在express-server中对es7的支持很好，语法检查也很完备
所以可以作为很好的初始版本。 整理好了之后，考虑向作者提出提交申请。

####步骤：
1. 构建express服务器
2. 连接mongodb
3. 构建graphql的schema
4. 查询数据

**这里做了一个很傻的决定，要在resolver中再从graphcool服务器取数据，取出来是没有问题，问题是数据 js对象和Json对象转换，很麻烦，取出的数据的转化在graphcool-framework 的rest-wrapper中 cnode API的数据获取中有模板文件**
遇到嵌套数据比较难处理。 
还有几个类似的服务器也在文件夹中，需要修改index.js的文件名

![查询结果](https://ws3.sinaimg.cn/large/006tKfTcgy1fnp7rp2nhcj30zf0glgmk.jpg)

```javascript
import {MongoClient, ObjectId} from 'mongodb'
import express from 'express'
import bodyParser from 'body-parser'
import {graphqlExpress, graphiqlExpress} from 'graphql-server-express'
import {makeExecutableSchema} from 'graphql-tools'
import cors from 'cors'

const URL = 'http://localhost'
const PORT = 3001
const MONGO_URL = 'mongodb://php-smarter:phpsmarter@ds239097.mlab.com:39097/recompose'

const prepare = (o) => {
  o._id = o._id.toString()
  return o
}

function fromMongo(item) {
  item.id=(item._id).toString();
  return  item
  
}

export const start = async () => {
  try {
    const db = await MongoClient.connect(MONGO_URL)

    //const context=await db.collection('books')
    //console.log(context);

    const typeDefs = [`
    type Book {
      id: ID!
      isbn: String!
      title: String!
      author: Author!
    }
    type Author {
      id: ID!
      name: String!
    }
    type Query {
      books(keyword:String): [Book]
      book(id: ID!): Book
    }

      schema {
        query: Query
        
      }
    `];

    const resolvers = {
      Query: {
        books: async (root,args, context) => {
          let findParams = {};
          
          console.log(args);
          if (args.keyword) {
            findParams.title = new RegExp(args.keyword, 'i')
            
          }
          //console.log('2:',db);
          const res=await context.db.collection('books').find(findParams).map(fromMongo).toArray();
          //console.log(context);
          return res;

       },
        book: async (root,{id, title}, context) => {
          //console.log(id);
          const result = await context.db.collection('books')
          .findOne({_id: new ObjectId(id) })
          return fromMongo(result)
        }
      }
     
    }


    const schema = makeExecutableSchema({
      typeDefs,
      resolvers
    })

    const app = express()

    app.use(cors())

    app.use('/graphql', bodyParser.json(), graphqlExpress({schema: schema, context: {
      db: db
    }}))

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

