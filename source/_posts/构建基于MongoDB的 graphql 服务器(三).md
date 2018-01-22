---
title: 构建基于MongoDB的 graphql 服务器(三)
subtitle: graphql-request的使用
date: 2018-01-22 20:18:28
categories: 技术备忘
tags: [Apollo,graphql]
---
#  graphql-request的使用
>graphql是graphcool的的client端，可以用于express服务器中请求数据，在resolver中也可以使用。apollo-client就只能用在在前端。 对于前端使用apollo-client绝对是最好的选择。目前没有对手。


做mutate处理，遇到不少问题，主要函数函数第一次接触，参数没有拼接对。一直以为是js对象转json的问题，早上一直在解决这个问题。结果还是参数的问题，模拟的数据是hotel的数据，其中嵌套有geolocation信息。 为这个嵌套，改了不同的组合，多没有出来， 结果正确拼接好以后，所有问题都没有了，数据是js对象还是json数据都可处理。   

接下来要遍历对象数组的时候问题依然是变量的拼接。 

代码如下，直接启动文件

```javascript
//从hotel 文件获取json数据然后写入到graphcool数据库

import express from 'express'
import bodyParser from 'body-parser'
import {graphqlExpress, graphiqlExpress} from 'graphql-server-express'
import {makeExecutableSchema} from 'graphql-tools'
import cors from 'cors'
import * as R from 'ramda'
var fs= require('fs');
var path=require('path')
require('es6-promise').polyfill();
require('isomorphic-fetch');
import fetch from 'node-fetch';
import { request } from 'graphql-request'
const URL = 'http://localhost'
const PORT = 3001
export const start = async () => {
  try {

    const typeDefs = [`
    type  geoData{
       longitude: Float!,
       latitude: Float!,
    }
    type Hotel{
      id: ID!  
      ratingStars: Int!
      name: String!
      streetAddress: String!
      postalCode: String!,
      cityLocalized: String!,
      geolocation:[geoData!]!
    }
    
    type Mutation {
      insertData(
       name: String
      ): Hotel
    }

    type Query{
       getHotels: [Hotel]
       geoDatas: geoData
       
    }
    
    
    `];

   const resolvers ={
     Mutation: {
       insertData:async (parent,args,context)=>{
        const query = `{
          allHotels(name:$name,
          streetAddress: $streetAddress,
          postalCode: $postalCode,
          cityLocalized: $cityLocalized,
          geolocation:{$longitude:longitude,$latitude:latitude}){
           name,
           geolocation{
             longitude,
             latitude
           }
         }
       }`;
       const variables={
        ratingStars: 8,
        name: "vvafo",
        streetAddress: "Hruggerstrasse 56",
        postalCode: "8400",
        cityLocalized: "Paden",
        geolocation: {latitude: 47.343960, longitude: 7.304224}
       };
       request('https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc', query,variables).then(data =>
       {
         console.log(data);
         return data

       })
          
         
        }

     },

    Query:{
      getHotels:async (parent,args,context)=>{
          
        const query = `{
           allHotels{
            id,
            name,
            geolocation{
              longitude,
              latitude
            }
          }
        }`
          
        request('https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc', query).then(data =>
        {
          console.log(data);
          return data

        })
        
       },

     }

}

   const schema = makeExecutableSchema({
      typeDefs,
      resolvers
    })

    const app = express()

    app.use(cors())
	app.use(express.static(__dirname))
    
    app.use('/graphql', bodyParser.json(), graphqlExpress({schema: schema}))

    const homePath = '/graphiql'

    app.use(homePath, graphiqlExpress({
      endpointURL: '/graphql'
    }))

    app.listen(PORT, () => {
      console.log(`Visit ${URL}:${PORT}${homePath}`)
    })

    InsertData();

  } catch (e) {
    console.log(e)
  }

}

//使用的是这个函数
var InsertData=()=>{
  const  mu= `mutation createOneHotel(
       $name:String!,
       $ratingStars:Int!,
       $streetAddress:String!,
       $postalCode: String!,
       $cityLocalized:String!,
       $longitude: Float!,
       $latitude: Float!

  ){
    createHotel(
      name:$name,
      ratingStars:$ratingStars,
     streetAddress:$streetAddress,
      postalCode:$postalCode,
      cityLocalized:$cityLocalized,
    geolocation:{latitude:$latitude, 
      longitude: $longitude}){
     id
     geolocation{
       longitude
       latitude
     }
   }
 }`;
 const Variables={
  name:"sdfsdlfrererjsldjfsl",
  ratingStars:11,
 streetAddress:"fdgtetwerwgeg",
  postalCode:"Hakerer ddome",
  cityLocalized:"Lordan",
  latitude: 47.343964, 
  longitude: 7.30424,
 };
 request('https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc', mu,Variables).then(data =>
 {
   console.log(data);
   return data

 })
    
};

```



