---
title: GraphQL query 实现的细节
date: 2018-02-24 23:57:50
categories: 技术备忘
tags: [GraphQL,Prisma]
---

>graphql在执行操作的时候,是如何体现灵活性的? 

-  `①查询字符串的组成`
![](https://ws2.sinaimg.cn/large/006tNc79gy1forz6hov5nj30zu0sg0tm.jpg)
-  `②解析`
![](https://ws4.sinaimg.cn/large/006tNc79gy1forz6j93zyj315i0hkjs6.jpg)
- `③再解析`
![](https://ws2.sinaimg.cn/large/006tNc79gy1forz6l13tpj30wg0eemyc.jpg)
- `④返回结果`
![`原来这里每个字段实际是独立的,每个 resolver是单独返回每个字段`](https://ws2.sinaimg.cn/large/006tNc79gy1foryswqfoxj31400n3wh2.jpg)

`原来这里每个字段实际是独立的,每个 resolver 实际是单独返回每个字段` 注意`③`和`④`的结果和返回的结果, 每个字段是单独返回的. 

