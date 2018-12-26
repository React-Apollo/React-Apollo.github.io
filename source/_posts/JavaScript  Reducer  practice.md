---
title: Dissecting Twitter's Redux Store
date: 2017-06-04 04:01:45
tags: Redux   
---
摘编|Dissecting Twitter’s Redux Store
[原文请见](https://medium.com/statuscode/dissecting-twitters-redux-store-d7280b62c6b1)
>剖析`mobile.twitter.com`的store结构.大公司的移动网站,可以借鉴的东西很多,twitter的mobile已经使用了React/Redux技术,所以如果你的web网站也想要采用React/Redux构架,这篇文章要好好看看.

原文我现在不想翻译.列出来可能遇到的问题和需要用到的技术
* 可能要自己翻墙
* 记住是` Twitter’s mobile website`移动网站,不是pc端网站,
网址是[mobileTwitter](https://mobile.twitter.com/home)
* 要使用chrome浏览器打开
* 申请一个twitter账号，登录,否则store中的信息很少
* 需要在chrome安装[ React Developer Tools (RDT) ](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en)
工具.

chrome的调试界面下可以看到
![React选线](https://ww2.sinaimg.cn/large/006tNc79ly1ff20tsol1sj303101u0n6.jpg)
点击，打开console.

* 输入 `$r.store.getState()`; 
* twitter在你应用中store的 state结构就展现出来了.
![twitter的state结构](https://ww2.sinaimg.cn/large/006tNc79ly1ff20xzpg5uj30mj0ecq40.jpg)
* 现在你可以看看大公司的应用是怎么来设计state的结构的.
* 由于人家的网站很复杂，所以state很像一个数据库，可以先看看数据库的范式化和 React/Redux中的实现方案 normalizr.了解如何减少巢状结构和冗余数据.

![数据的范式化](https://ww1.sinaimg.cn/large/006tNc79ly1ff21394wxvj30m80cr0wn.jpg)

>其他有兴趣的再深挖吧.总之一句话,当React应用中引入了Redux以后,应用的控制权就交到了Redux的手中,所以不要局限于React组件和页面的,需要更过的考虑数据的组织问题. 

这一篇算是工具篇。 相关的开发工具后redux-logger, dev-tools, React-native Debugger ,Reactotron工具.好像还有一个可视化的工具