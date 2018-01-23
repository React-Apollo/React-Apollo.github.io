---
title: 构建基于MongoDB的 graphql 服务器(四)
subtitle: gDom, graqhql-request方法，还有函数式编程方法
date: 2018-01-24 4:50:28
categories: 技术备忘
tags: [Apollo,graphql]
---
#  构建基于MongoDB的 graphql 服务器(四)
>设想是给graphcool数据库提供一些数据，考虑最近看Medium网站较多，所以抓取这里边的信息.

方法和前面的大同小异，  这里实际算是一个完整的流程了。  

1. 使用gDom的grqhql方法选择dom元素。 
2. 根据Dom元素来定graphql查询中shcema
3. 数据消毒处理
4. 通过graphcool的方法，插入数据库

难点是`schema`的建立，和两个主操作的异步处理问题，使用了flow方法，让以异步流程转为类似compose的以异步方法。
 


```
/*****************
 *  从medium抓取一下感兴趣的内容，放到app中
 * *******************/
'use strict'
import express from 'express'
// import bodyParser from 'body-parser'
import cors from 'cors'
import * as R from 'ramda'
import { request } from 'graphql-request'
import mediumData from '../dist/mediumData'// 导入的数据
// import new_hotel from '../dist/new_hotel'
// var fs = require('fs')
// var path = require('path')
const mediumUrl='https://medium.com/search?q=React-native';
const variables = {
  url: 'https://medium.com/search?q=hoc',
}
const gDomApi='http://gdom.graphene-python.org/graphql';
const URL = 'http://localhost'
const PORT = 3001
// graphcool endpoint
const api = 'https://api.graph.cool/simple/v1/cjcrwz0tg3jyf0153l824cpyh'
var _ = require('lodash');
var flow=require('nimble');
var Promise = require("bluebird");
// graphql模板
const mu = `mutation getMediumList(
   $title:String!,
   $subTitle:String!,
   $authorName:String!,
   $avatarImage: String!,
   $shortPassage:String!,
   $url: String!,
   $clap: String!

){
   createMedium(
   title:$title,
   subTitle:$subTitle,
   authorName:$authorName,
   avatarImage:$avatarImage,
   shortPassage:$shortPassage,
   url: $url,
   clap:$clap,
   ){
      id,
      title
   }

}`

const que =`query getMedium($url:String!){
     page(url: $url) {
         items: query(selector: "div.js-postListHandle .js-block"){
         title: text(selector: "div h3")
         subTitle: text(selector: "div h4")
         url:attr(selector:"div .postArticle-content a",name:"href")
         shortPassage: text(selector: "div p")
         avatarImage:attr(selector:".postMetaInline-avatar img"name:"src")
         authorName: text(selector: "div .postMetaInline:first-child")
         clap: text(selector: "div .js-actionMultirecommendCount  ")
         }  
     }
}`

export const start = async () => {
  try {
    const app = express()

    app.use(cors())
    app.use(express.static(__dirname))
    app.listen(PORT, () => {
      console.log(`Visit ${URL}:${PORT}`)
    })
    
    Promise.try(insertData(variables)).then(
        console.log("done")

    );
  } catch (e) {
    console.log(e)
  };
}

// 获取数据的方法
const handleGrqphcoolDataTemplate = R.curry((api, template, variables) => (
 request(api, template, variables).then(data => {
   //console.log(data.page.items);
   return data;
 })
))
// 柯理化  等待抓取的数据
const graphqlRequestMethodWaitForData = handleGrqphcoolDataTemplate(api, mu);

const insertDataWaitForData = R.map(graphqlRequestMethodWaitForData);
// 从Medium 网站获取数据的方法是一样的的，柯理化是处理参数不同,抓取是变量是网站地址
//抓取后的数据作为insertDataWaitForData的数据

const getDataFromMediumWaitForUrl = handleGrqphcoolDataTemplate(gDomApi, que);

//const xHeadYLens = R.lensPath(['page', 'items']);
//const getArray = R.view(xHeadYLens);
// 这是从reddit中找的异步执行的方法
const _wrapFlowAsync = (fn) => (arg) => Promise
  .try(() => arg)
  .then(fn);

const flowAsync = (...fns) => {
 
  const wrappedFns = fns.map(fn => _wrapFlowAsync(fn))
  return _.flow(wrappedFns)
}
const getArray = (obj) => obj.page.items;
const insertData = flowAsync( getDataFromMediumWaitForUrl, getArray , insertDataWaitForData)
```
