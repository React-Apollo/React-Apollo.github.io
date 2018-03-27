---
title: 聊天软件的 Prisma_DataModel
date: 2018-02-23 22:08:10
categories: 技术备忘
tags: [Graphcool,Prisma]
---
>基于 [Chatty clone](https://medium.com/react-native-training/building-chatty-part-2-graphql-queries-with-express-6dce83b39479)

### 数据的关联模型
- 一个用户可以属于多个小组, 有多个朋友, 有多条消息
- 一个小组可以有多个用户,可以有多条消息
- 一条消息来自于一个用户, 发送给某个或某几个组  多播
- 系统消息可以发送给所有组.广播

### 流程
具体的模型流程来自 *Node in Action* 

 1. 用户注册流程  
 2. 加组,如果组不存在就创建新的
 3. 发送消息, 获取用户名,来自组名, 发送到组, 消息内容


```js
type User {
	id: ID! @isUnique
	email: String @isUnique
	username: String!@isUnique
	password: String!
	userOfGroups: [Group!]@relation(name: "userOnGroup") #一个用户可以属于一个小组
	userOfFriends: [User]   #一个用户可以有多个朋友
	userOfMessages: [Message]@relation(name: "userOfMessage") #一个用户有多条消息
    createdAt: Date!
    updatedAt:Date!
}

type Group {
	id: ID!@isUnique
	nameOfGroup: String
	usersOfGroup: [User]@relation(name: "userOnGroup")# 一个小组有多个用户
	messagesOfGroup: [Message]@relation(name: " messageOfGroup") #一个小组可以有多条消息
    createdAt: Date!
    updatedAt:Date!
}

type Message {
	id: Int!
	toGroup: [Group]@relation(name:"messageOfGroup") #一条消息可以发送多个组
	fromUser: User!@relation(name:"userOfMessage")#一条消息有一个发送用户
	text: String!
	createdAt: Date!
    updatedAt:Date!
}
```



