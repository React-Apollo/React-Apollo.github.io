---
title: Promise的例子
date: 2019年1月15日,下午2:44
categories: 技术备忘
tags: [Javascript,Async]
---


{{TOC}}

 # Promise的使用
> 根据阮一峰的博客内容
##  Promise对象的使用在事件循环中有优先级

### 如果异步事件在第一轮就可以resovle,就在第一轮中返回


 <iframe
  src="https://carbon.now.sh/embed/?bg=rgba(171%2C%20184%2C%20195%2C%201)&t=seti&wt=none&l=auto&ds=true&dsyoff=20px&dsblur=68px&wc=true&wa=true&pv=56px&ph=56px&ln=false&fm=Hack&fs=14px&lh=133%25&si=false&code=setTimeout(function()%2520%257B%250A%2520%2520console.log(1)%253B%250A%257D%252C%25200)%253B%250A%250Anew%2520Promise(function%2520(resolve%252C%2520reject)%2520%257B%250A%2520%2520resolve(2)%253B%250A%257D).then(console.log)%253B%250A%250Aconsole.log(3)%253B%250A%252F%252F%25203%250A%252F%252F%25202%250A%252F%252F%25201&es=2x&wm=false"
  style="transform:scale(0.8); width:1024px; height:473px; border:0; overflow:hidden; margin-right:auto"
  sandbox="allow-scripts allow-same-origin">
</iframe>

输出为 3，2，1 
第一个setTimeout函数中的回调函数会在第二轮事件循环中执行，
第三个函数会在本轮事件循环中立刻执行
第二个函数比较微妙， promise对象的回调函数没有延迟，并不会等到第二轮事件循环中执行， 在第一轮循环的最后就会执行。


如果修改一下， promise对象中的函数有延迟，如下

![](https://ws4.sinaimg.cn/large/006tNc79gy1fz7ak9eg2cj30qm12mn14.jpg)

添加的第三个函数有延迟，在第一轮循环中还不能完成，会进入到第二轮循环。解析完成后会在第二轮或者后续的时间循环中返回。

