---
title: 使用函数式方法批量导入数据
date: 2018-01-23 5:24:28
categories: 技术备忘
tags: [graphql,express,ramda,tranducer]
---

>从数据源来的数据，json文件格式，或者是数组， 批量导入到graphcool数据库中。 `使用了函数式编程中的ramda.js 和tranducers-js.js`的方法，  
## 问题分解
1. 遍历数组，采用map方法
2. 映射单个对象属性到variable
3. 单个对象的变量插入到数据库中

##  解决办法
这里使用函数式编程来处理问题，函数式并不是高深的技术，只是简化了处理问题的流程
![](https://ws3.sinaimg.cn/large/006tKfTcgy1fnq56t1x6xg30zk0as41k.gif)
常规的处理流程
![](https://ws2.sinaimg.cn/large/006tKfTcgy1fnq58bysdhg30x408wt9w.gif)
transducer的处理流程

### 数据结构：
```
{ ratingStars: 4,
  name: 'Hotel Europe',
  streetAddress: 'Dufourstrasse 4',
  postalCode: '8008',
  cityLocalized: 'Zürich',
  geolocation: {latitude: 47.364185, longitude: 8.547145}
}
```
**这里有嵌套的结构**，在graphql-request要使用扁平的结构，所以需要对数组对象中的的单个对象做映射处理，然后再插入数据库。使用`transducer`原理，不在先处理映射，然后函子，接着再map方法，插入的数组。 对单个对象的处理可以通过tranducer方式放到一起一并处理。 这里的思想是很精妙的。

####  具体的操作方法
在express服务器上运行
##### 请求函数柯理化
```javascript
//首先传入API，template,等待数据
//变量放在最后，有可能用于compose函数
const func = R.curry((api, template, variables) => (
    request(api, template, variables).then(data => {
      console.log(data)
    })
  ))
```

##### 扁平化对象数据
```javascript
var flattenData = function (n) {
  return {
    name: n.name,
    ratingStars: n.ratingStars,
    streetAddress: n.streetAddress,
    postalCode: n.postalCode,
    cityLocalized: n.cityLocalized,
    latitude:  n.geolocation.latitude,
    longitude: n.geolocation.longitude,

  }
};
```

#####  函数式方法的一些处理过程
```
const waitForData = func(api, mu); //柯理化

//xf是transducer的过程，对于单个对象的连续处理可以在这里实现
// 方向是从左=>右，

var xf = t.comp(R.map(flattenData), R.map(waitForData));

//这个中间函数有做了柯理化，等待作用的数组数据，这里不是对象了
//流程就是接受数组对象，取出`单个对象`，使用tranducer进行处理
const mediateFunc=R.curry((xf,data)=>(t.into([], xf, data)));
const  getFinalRes=mediateFunc(xf);
getFinalRes(data);
```

##### 整个代码
```

'use strict'
// 从hotel 文件获取json数据然后写入到graphcool数据库
import express from 'express'
import bodyParser from 'body-parser'
import cors from 'cors'
import * as R from 'ramda'
var fs = require('fs')
var path = require('path')
require('es6-promise').polyfill()
require('isomorphic-fetch')
import fetch from 'node-fetch'
import { request } from 'graphql-request'
import hotelData from '../dist/hotelData'//导入的数据
const URL = 'http://localhost'
const PORT = 3001
const api = 'https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc'; //graphcool API
//graphql模板
const mu = `mutation createOneHotel(
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
}`
var t = require('transducers-js');//导入transducers-js执行tranducer操作
export const start = async () => {
   try{
     const app = express()

    app.use(cors())
    app.use(express.static(__dirname))
    app.listen(PORT, () => {
      console.log(`Visit ${URL}:${PORT}`)
    });
    //直接从文件读取，不成功，但是导入是可以的,说明数据的操作是没有问题的，继续再试s
   // fs.readFile(path.resolve(__dirname,'hotel.json'), function(err,data){
   //   if(err) throw err;
   //      //console.log(data.toString());
   //      const hotelData=data.toString();
   //     //console.log(typeof(data);
   //      //const Data=data.toString();
   //      //InsertData(Data);
   //      console.log(typeof(hotelData));
   //  });
      
   InsertData(hotelData);
  
  } catch (e) {
    console.log(e)
  };
};


var InsertData =(data) => {
  // console.log(data);
  //请求方法的柯理化，首先传入api和template，等待变量
  
  const func = R.curry((api, template, variables) => (
    request(api, template, variables).then(data => {
      console.log(data)
    })
  ))
  
  var flattenData = function (n) {
  return {
    name: n.name,
    ratingStars: n.ratingStars,
    streetAddress: n.streetAddress,
    postalCode: n.postalCode,
    cityLocalized: n.cityLocalized,
    latitude:  n.geolocation.latitude,
    longitude: n.geolocation.longitude,

  }
};

const waitForData = func(api, mu);
var xf = t.comp(R.map(flattenData), R.map(waitForData));

 const mediateFunc=R.curry((xf,data)=>(t.into([], xf, data)));
const  getFinalRes=mediateFunc(xf);
getFinalRes(data);
};

```







