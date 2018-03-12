---
title: 摘要|Offline-First Web Application Using Redux and PouchDB
date: 2018-03-12 10:07:01
categories: 技术备忘
tags: [React-Native,offline]
---

[`摘要|Offline-First Web Application Using Redux and PouchDB`](https://stories.jotform.com/offline-first-web-applications-d2d321444510)

>5步构建离线优先web 应用

## 离线应用使用本地存储作为主要数据源, 数据不断和远程数据库同步
## 为什么使用离线优先的模式?
离线优先的应用有如下有点:

1. 页面加载更高效
2. 离线,在线工作状态没有区别
3. 避免偶然的数据丢失. 

## 使用 React,Redux和 PouchDB

### 1.React和 Redux 构架

  Redux作为 React 的数据管理工具, 模式是单一 store
  
### 2.PouchDB
 PoucdDB来源于 couchDB, 属于客户端的 NO-SQL 数据库. 用来存储本地数据
 
 
### 3.如何使用 Redux 和 PouchDB

可以使用开源的包:`redux-pouchdb`  

![](https://ws3.sinaimg.cn/large/006tNc79gy1fp9tibrd7rj30ww0m8jtj.jpg)

之后只需要导出 reducer 就可以了

### 4. 本地数据和远程数据库同步

#### a)使用 CouchDB
 使用CouchDB 的原因是,它和 pouchDB 同步很容易. PouchDB提供了同步的方法,允许单向或者双向同步. 只需要在开始的时候使用 Pouch.sync.
#### b)使用已经存在的数据库
PouchDB 在后台会一直尝试和远程数据库建立连接, 如果网络状态不稳定,等到有网络连接时,后台就会执行同步操作,发送离线数据

**如果用户关掉窗口怎么办?**
所有的变化都保存在 reducer 中,并和 PouchDB 同步. 所以如果用户关掉窗口,数据也不会丢失. 

### 5. Service Workers









