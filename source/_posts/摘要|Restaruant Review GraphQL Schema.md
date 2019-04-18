---
title: 摘要|Restaruant Review GraphQL Schema
date: 2019-02-09 07:56
categories: 技术备忘
tags: [React,GraphQL]
---


## 主要流程

- 🔘 设计APP需要的数据类型
- 🔘 返回“分页”处理的列表数据
- 🔘 考虑APP应该具有的合理需求，然后设计操作
- 🔘 为GraphQL查询编写输入类型
- 🔘 从安全角度考虑认证的需求

## 初始数据类型
- 🔘 `拥有者`， 可以添加restaurant 到数据库
- 🔘 `认证用户` 可以给restaurant写评价
- 🔘 `认证用户` 可以给为 restaurant添加favorite标记
- 🔘 `认证用户` 可以查看喜欢restaurant的列表
- 🔘 没有认证用户  可以搜索restaruant,查看评分
- 🔘 `认证用户`  可以看到某个restaurant的具体评论
   
     **添加标记的需要在执行流程前执行授权检测**
     
 ## 有三个基本类型
   1. User 
   2. Location, restaurant的位置
   3. Review

 ##  基础的GraphQL Schema
 
 ```graphql
 type User {
  id: ID!
  name: String!
  email: String
  locations: [Location]
  reviews: [Review]
  favorites: [Location]
}

type Location {
  id: ID!
  owner: User!
  name: String!
  longitude: Float
  latitude: Float
  address: String
  averageRating: Float
  favoritesCount: Int
  reviews: [Review]
}

type Review {
  id: ID!
  owner: User!
  location: Location!
  content: String!
  rating: Number!
}
 ```


