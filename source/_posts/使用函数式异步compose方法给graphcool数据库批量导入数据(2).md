---
title: 使用函数式异步compose方法给graphcool数据库批量导入数据(2)
date: 2018-01-24 17:20:28
categories: 技术备忘
tags: [Ramda,graphql]
---
# 异步compose方法批量导入数据流程
>解决链式数据流程的异步流程同步化办法

### 问题
在[https://react-apollo.github.io/2018/01/24/构建基于MongoDB的%20graphql%20服务器(四)](https://react-apollo.github.io/2018/01/24/构建基于MongoDB的%20graphql%20服务器(四)/)已经实现了了数据的流程，但是具体的处理方法上很不Ramda,经过连夜奋战，但是问题存在：
对于async/await的基础流程不太清楚，所以绕了弯路，console.log会报错，但是结果是插入数据库了，问题在刚开始console.log，抓取的事件还没有完成在获取函数之后打印是没问题的，但是在获取函数之内就出问题，原因在于`远程获取函数之内的打印并没有受到async的控制`。
 ### 解决办法
 终于在网上找到一个异步版本的compose函数，解决了这个问题。comopse函数组合的子函数都要是添加await关键字的，这样做，从流程：远程数据=>数据去毛=>插入数据库的路程才可以顺序执行。正常的流程是这样。因为js的事件轮训机制， 数据去毛的过程可能在数据没有返回(网络请求有延迟)的情况下就会执行，这样就获取不到数据，但是在远程数据回来以后就会有结果了，所以这里的数据去毛，还有数据库插入数据的操作会提示输入参数`undefined`,但是结果是可以运行的。[`异步版本的compose函数`](https://gist.github.com/jperasmus/fbbcccb387896ff7db2c58797ebb76da)

   ```
   // Async compose
const compose = （...functions) => input => functions.reduceRight((chain, func) => chain.then(func), Promise.resolve(input));

// Functions fn1, fn2, fn3 can be standard synchronous functions or return a Promise
compose(fn3, fn2, fn1)(input).then(result => console.log(`Do with the ${result} as you please`))
   ```
   `异步版本的compose的关键点是使用reduce函数组合子函数时，reduce是异步版本，简单说给就是把每个函数都变为promise对象`
   



[直接从json文件获取的数据批量插入](https://react-apollo.github.io/2018/01/23/在graqhcool%20数据库批量插入数据/)
现在这个版本是使用了[Gdom-基于graphql和python的页面抓取工具](http://gdom.graphene-python.org/graphql?query=%7B%0A++page%28url%3A%22http%3A%2F%2Fnews.ycombinator.com%22%29+%7B%0A++++items%3A+query%28selector%3A%22tr.athing%22%29+%7B%0A++++++rank%3A+text%28selector%3A%22td+span.rank%22%29%0A++++++title%3A+text%28selector%3A%22td.title+a%22%29%0A++++++sitebit%3A+text%28selector%3A%22span.comhead+a%22%29%0A++++++url%3A+attr%28selector%3A%22td.title+a%22%2C+name%3A%22href%22%29%0A++++++attrs%3A+next+%7B%0A+++++++++score%3A+text%28selector%3A%22span.score%22%29%0A+++++++++user%3A+text%28selector%3A%22a%3Aeq%280%29%22%29%0A+++++++++comments%3A+text%28selector%3A%22a%3Aeq%282%29%22%29%0A++++++%7D%0A++++%7D%0A++%7D%0A%7D)

<iframe src="http://gdom.graphene-python.org/graphql?query=%7B%0A++page%28url%3A%22http%3A%2F%2Fnews.ycombinator.com%22%29+%7B%0A++++items%3A+query%28selector%3A%22tr.athing%22%29+%7B%0A++++++rank%3A+text%28selector%3A%22td+span.rank%22%29%0A++++++title%3A+text%28selector%3A%22td.title+a%22%29%0A++++++sitebit%3A+text%28selector%3A%22span.comhead+a%22%29%0A++++++url%3A+attr%28selector%3A%22td.title+a%22%2C+name%3A%22href%22%29%0A++++++attrs%3A+next+%7B%0A+++++++++score%3A+text%28selector%3A%22span.score%22%29%0A+++++++++user%3A+text%28selector%3A%22a%3Aeq%280%29%22%29%0A+++++++++comments%3A+text%28selector%3A%22a%3Aeq%282%29%22%29%0A++++++%7D%0A++++%7D%0A++%7D%0A%7D" style="width:90%; height:400px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allrow-popups allow-scripts allow-same-origin">
</iframe>

### 从medium网站获取数据的查询语句(具体细节省略了，不能作为实际的使用，类型大致如此)
```javascript
{
  page(url: "https://mediumq=graphcool") {
    items: query(selector: "div") {
	       title: text(selector: "div h3")
	       subTitle: text(selector: "div h4")
	       url:attr(selector:"div a",name:"href")
	       shortPassage: text(selector: "div p")
	       avatarImage:attr(selector:".postMetaInline-avatar img"name:"src")
	       authorName: text(selector: "postMetaInline:first-child")
	       clap: text(selector: "div .js-actionMultirecommendCount  ")
    }  
  }
}
```

`异步版本的数据操作流程实际是和前面的版本是相同的，只是compose函数是异步的。`
第一步从网站抓取数据是异步的，第三步插入graphcool数据库是异步的。
所以传统的compose函数就不能使用了。需要使用异步的compose。

### 获取数据的方法
简单讲就是graphql 版本的get和post方法
```
//柯理化版本以便于后面构造compose
const handleGrqphcoolDataTemplate = R.curry((api, template, variables) => (
 request(api, template, variables).then(data => {
   //console.log(data.page.items);
   return data
 })
))
```

### 具体的数据流代码
```
// #获取数据的方法-简单描述就是graphql版的get和post方法，只要是和
const handleGrqphcoolDataTemplate = R.curry((api, template, variables) => (
 request(api, template, variables).then(data => {
   //console.log(data.page.items);
   return data
 })
))

/** ++第一步构建从medium网站通过grapql查询获取方法的工厂++
从Medium 网站获取数据的方法是一样的的，柯理化是处理参数不同,抓取变量是网站地址
抓取后的数据作为insertDataWaitForData的数据
工厂组装完成，只等待传入medium的网址就可以工作了 **/
const getDataFromMediumWaitForUrl = handleGrqphcoolDataTemplate(graphqlUrlForRemoteData, schemaForGetDataFromRemote)

/* ++第二步构建的工厂专门拔猪毛 毛🐽变光🐷，等待光🐽 */
const getArray = (obj) => obj.page.items

// 柯理化  等待抓取的数据
const graphqlRequestMethodWaitForData = handleGrqphcoolDataTemplate(api, qu)
/*++第三步插入数据的graphcool操作++ 由于是从数组获取的数据，这里就
使用map方法进行遍历处理
*/
const insertDataWaitForData = R.map(graphqlRequestMethodWaitForData)

//异步的compose函数
const compose = (...functions) => input => functions.reduceRight((chain, func) => chain.then(func), Promise.resolve(input))
//构建的整个流程的工厂
const insertData = compose(insertDataWaitForData, getArray, getDataFromMediumWaitForUrl)
```


<script src="https://embed.cacher.io/85563fd55960fb46f8f9409b08781cf12c5afc10.js?a=d09cd283fe294be41b583f3ee54c1787&t=monokai_sublime"></script>



