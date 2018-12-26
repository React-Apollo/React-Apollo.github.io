---
title: Cnoder 项目列表
date: 2018-01-29 12:21:07
categories: Readme
tags: [Graphcool,node.js, Apollo,expo]
---

[![Join the chat at https://gitter.im/LouisBarranqueiro/hexo-theme-tranquilpeak](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/LouisBarranqueiro/hexo-theme-tranquilpeak?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
## 内容 ##

- [项目内容](#项目内容)
- [文件结构](#文件结构)

### 项目内容 ###
### 文件结构 ###
![](https://ws3.sinaimg.cn/large/006tNc79ly1fnxd2nsb1oj305s0dr0sq.jpg)
根据 F8APP的文件结构做了文件夹重新安排, 从导航触发,这里不会提前登陆, 只有导航到my Tab时点击登录才会通过github登录.每个 tab 下面是 StackNavigator,这样导航就是树形结构, 每个 tab作为父节点, 下面的导航是专项的, 有公用的作为 publicRoute的形式,导入每个 tab下面.例如几个地方会用到 detail页面,这个作为公共的导航页面,放到 common文件夹下.还有 Utils工具,commonent组件

