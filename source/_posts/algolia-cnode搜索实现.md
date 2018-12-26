---
title: algolia-cnode即时搜索实现- React版
date: 2018-03-04 14:59:12
categories: 技术备忘
tags: [Graphcool,algolia,cnode,express]
---

> 参考的文献是:  [Algolia Auto-Sync for GraphQL backends](https://medium.com/@graphcool/algolia-auto-sync-for-graphql-backends-f78678f45889). 实现了 Graphql 数据数据添加和删除时的数据同步

基本流程是,你给 algolia 提供一个需要索引的文本或者资源, algolia 会做出索引,
之后就可以使用提供的 API获取结果. 

总共索引了1-95页的数据, 可能排序上还要优化, 方法现在没有问题

基础流程没有什么问题.遇到的问题是,之前从 medium 网站抓取了300多篇文章, 建完索引之后,没有结果. algolia 实现的是在建立索引机制以后的数据才可以使用, 我索性把 cnode 1-95页的数据都建了索引. cnode 每页是40条, 总共是3800条数据, 现在有3600数据加了索引,没有插入的还没看是什么原因.
## 大概步骤
项目分为四大块:`①`:后台服务器,组要是由于目前在使用 graphql,觉得很有潜力,而且 graphcool 提供了 algolia 的整合服务,使用还是比较简单的,主要工作是建立模型,导入和 aloglia 对接的 APP ID和 Token.  `②`: algolia
上的配置, 主要 是获取 APPID和 Token.  `③`:  从 cnode,导入数据,严格说这一部分和这里的文章关系不太大.
`④`: 前端的配置, 这个有教程,最简单的异步, 获取数据的方法都封装好了, 直接使用即可.  

## 实现的结果

![](https://ws3.sinaimg.cn/large/006tNc79gy1fp0u1bkut2g30am0djnp6.gif)

##  实现方案
###  注册,建立应用,获取 APPID
- `①`登录:[https://www.algolia.com](https://www.algolia.com),注册直接用 github 登录. 
- `②`:点击右上角 dashboard 进入管理界面
- `③`: 点击![](https://ws1.sinaimg.cn/large/006tNc79gy1fp0u9165tej306e026742.jpg) 创建一个应用
- `④`:进入应用,其他不动, 我们只会使用到 key, 点击钥匙![](https://ws2.sinaimg.cn/large/006tNc79gy1fp0ubg7zkqj301e01m0k5.jpg)
-  `⑤`: 这里会有一个 search-only-key,专门用于前端搜索用的, 我们在 all api key下创建一个新的有用读写记录的key. 注意还有 application ID
-  `⑥` 点击![](https://ws3.sinaimg.cn/large/006tNc79gy1fp0uemyd9ij304a01fq2p.jpg) 
-  `⑦`: 设置,名字,还有权限,只需要读写的权限就可以了.点击生成, 
    ![](https://ws3.sinaimg.cn/large/006tNc79gy1fp0ugd2p7yj30dh05zmx4.jpg)
    ![看到的结果是有读写的内容](https://ws2.sinaimg.cn/large/006tNc79gy1fp0ujexw3ej30gm047jra.jpg)
     而搜索的 key是这样
     ![only search](https://ws4.sinaimg.cn/large/006tNc79gy1fp0ulthfccj30e402at8j.jpg)
    
    通过以上的步骤,现在我们有三个要使用的 id, 一个应用的 ID,一个所有使用的key,一个用于配置服务的key.  由于用于索引的数据都是从后台同步的,这里目前就不要再做任何的工作了. 后续可以做些优化工作.
    
###  后台服务服务的建立        
####  建立模型
- 创建graphcool服务器, 这个参看 graphcool网站的教程, 
- 建立模型  
   
   ![](https://ws1.sinaimg.cn/large/006tNc79gy1fp0uqwqv8mj305e049wea.jpg)

创建了一个简单的模型包含有 title,content, tab 字段,添加其他的也可以.首要任务是跑通流程

使用整合服务
  ![](https://ws3.sinaimg.cn/large/006tNc79gy1fp0usjkvmvj30530733yb.jpg)
  
   整合 aloglia 的服务, 点击进入
添加key

   ![](https://ws2.sinaimg.cn/large/006tNc79gy1fp0utvc97uj30c201nq2q.jpg)
   
   
   ![](https://ws3.sinaimg.cn/large/006tNc79gy1fp0uurf9zoj30fe09xweg.jpg)
   
   
   **`有两个key,我们要使用允许读写的的那个key才行`**

点击![](https://ws2.sinaimg.cn/large/006tNc79gy1fp0uwrd9h6j302z0130o6.jpg) 

添加index.

```js
 
{
    node {
      content
      tab
      title
    }
  }
```  

---
点击创建 index,我们的配置工作就完成了
现在可以添加一条索引,验证一项 algolia 会不会自动同步数据

![](https://ws3.sinaimg.cn/large/006tNc79gy1fp0uzl3kthj30yj06n74c.jpg)   
   
 dashboard 中如果有记录,证明数据同步成功了.如果这里是0,要看看前面的配置有没有问题,如果有问题,不要急着做下一步, 到这里配置就完成了, 导入数据和配置是独立的过程.
 
 ![](https://ws4.sinaimg.cn/large/006tNc79gy1fp0v1aiw8cj30fq05pt8l.jpg)
 
   在 graphcool 手动输入一条信息, algolia如果有记录出现,配置完成
   接着进行下一步, 导入数据

###  导入数据, 这里不详细说, 通过 cnode的 API获取数据,然后依照 graphql 的mutate 方法,导入到 Graphcool 的数据库.参见下面的代码

```
'use strict'
import express from 'express'
import bodyParser from 'body-parser'
import cors from 'cors'
import * as R from 'ramda'
var path = require('path')
require('es6-promise').polyfill()
require('isomorphic-fetch')
import fetch from 'node-fetch'
import { request } from 'graphql-request'
const dataArray = []
var t = require('transducers-js') // 导入transducers-js执行tranducer操作
const URL = 'http://localhost'
const PORT = 3001
const api = 'https://api.graph.cool/simple/v1/cjearwrd40zes01671xikrsnh' // graphcool API
// graphql模板-数据插入的模板
const mu = `mutation createList(
  $tab: String!,
  $content:String!,
  $title: String!
){
 createList(
    content: $content,
    tab:$tab,
    title:$title,
   ){
        id
    }

}`
//主方法
export const start = async () => {
  try {
  const app = express()

		app.use(cors())
		app.use(express.static(__dirname))
		app.listen(PORT, () => {
  console.log(`Visit ${URL}:${PORT}`)
		})
		const startTime = Date.now()
		

		for (var i = 1; i <= 95; i++) {
    const pageData = await singlePageData(i) //获取单页数据
			  dataArray.push(pageData) 
		}

    const flattenData = R.flatten(dataArray)
    const getData = compose(R.map(insertData), flattenData)
		await getData(dataArray); //插入数据库
		const endTime = Date.now()
		const spend = endTime - startTime
		console.log('spending time:', spend)
	} catch (e) {
  console.log(e)
	}
}
//单条记录插入 graphcool数据库的方法
const insertData = data => {
  var flattenData = function (n) {
  return {
  content: n.content,
  tab: n.tab,
  title: n.title
}
	};
//数据插入 graphql 数据方法柯理化
  const func = R.curry((api, template, variables) =>
		request(api, template, variables).then(data => {
  console.log('data:', data)
		})
	)

	const waitForData = func(api, mu)
	var xf = t.comp(R.map(flattenData), R.map(waitForData))
 //这里用了 transducer.js 的方法
	const mediateFunc = R.curry((xf, data) => t.into([], xf, data))
	const getFinalRes = mediateFunc(xf)
	getFinalRes(data)
};

//异步 compose 方法
const compose = (...functions) => input =>
	functions.reduceRight((chain, func) => chain.then(func), Promise.resolve(input))
//拼接 API的方法
const variablesTemp = num => `https://cnodejs.org/api/v1/topics?page=${num}`
//获取数据,并取出 data字段的方法
const fetchData = url => fetch(url).then(res => res.json()).then(data => data.data)
//异步 compose 组合的获取 API url 并 获取数据的方法
const singlePageData = compose(fetchData, variablesTemp)
```

插入数据以后, 在 graphcool 后台可以看到记录数, 在 algolia的 dashboard 也可以看到记录数.  整个配置和数据导入就完成了. 

由于我们这里是从 cnode获取手动获取数据, 如果是原生使用 Graphcool 的数据库, 插入条目以后,会立刻自动通过. 用 cnode 的 API稍微麻烦一点

### 前端的配置
React/React-Native的配置
可以在github搜索,有很多代码实例

#### app.js 文件配置 导入 app ID 和仅用于搜索的 key和 index name.这个 name 是在后台配置时建立的, algolia 显示的就是这个名字. 

```
import React from "react";
import { Text, View } from "react-native";
import { InstantSearch } from "react-instantsearch/native";
import styles from "./src/styles";
import SearchBox from "./src/SearchBox";
import Results from "./src/Results";

export default class App extends React.PureComponent {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.brandTitle}>Medium Search</Text>
        <InstantSearch
          appId="BA28CTOPE6"  
          apiKey="19348cf2875c2023552115b820856f9d"
          indexName="cnodeList"
        >
          <View style={styles.searchBoxContainer}>
            <SearchBox />
          </View>
          <Results />
        </InstantSearch>
      </View>
    );
  }
}
```

#### Searchbox.js  输入的数据和 algolia 发生联系的组件

```js
import React from "react";
import { TextInput } from "react-native";
import { connectSearchBox } from "react-instantsearch/connectors";
import styles from "./styles";

const SearchBox = connectSearchBox(({ refine, currentRefinement }) => {
  return (
    <TextInput
      style={styles.textBox}
      onChangeText={text => refine(text)}
      value={currentRefinement}
      placeholder="Search Something"
      clearButtonMode="always"
      spellCheck={false}
      autoCorrect={false}
      autoCapitalize="none"
    />
  );
});

export default SearchBox;
```


#### List 列表显示数据

```js
import React from "react";
import { FlatList } from "react-native";
import { connectInfiniteHits } from "react-instantsearch/connectors";
import Repository from "./Repository";
import ItemSeperator from "./ItemSeperator";

const Results = connectInfiniteHits(({ hits, hasMore, refine }) => {
  const onEndReached = () => {
    if (hasMore) {
      refine();
    }
  };
  //终端打印搜索数据
  console.log(hits);

  return (
    <FlatList
      data={hits}
      onEndReached={onEndReached}
      keyExtractor={repo => repo.objectID}
      renderItem={({ item }) => <Repository repo={item} />}
      ItemSeparatorComponent={ItemSeperator}
    />
  );
});

export default Results;
```
 
具体的 item,就不写了. 其实上面 console.log 打印出数据整个流程就完成了.在 algolia 的 dashboard 也可以查看搜索的情况
![](https://ws4.sinaimg.cn/large/006tNc79gy1fp0vufjl5ij30ng0baq33.jpg)


**整个即时搜索的流程完成, 速度还是挺快的, 大部分工作人家的算法帮我们完成了**.

如果查看页面发现还有许多要优化的地方,后面再说.


 
  



