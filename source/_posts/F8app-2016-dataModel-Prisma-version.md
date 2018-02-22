---
title: F8App_DataModel_Prisma_version
date: 2018-02-22 21:52:32
categories: 技术备忘
tags: [Graphcool,Prisma]
---


> F8App GraphQL 服务器 Prisma版本的Datamodel重构版
`添加了关联的类型, Tag类型`, 关联条件实际只有`演讲↔️演讲者`, `演讲↔️地图`,`演讲↔️标签的关系`


```
type Agenda {
  id: ID! @unique
  startTime:String
  endTime:String
  speakers:[Speaker] @relation(name:"AgendaBySpeaker") #一个 agenda可以有多个发言者
  tags:[Tag!]! # 一个 Agenda可以有多个 tag, 不会发生歧义所以不用@ relation关联条件
  allDay:Boolean@default(value:"false")
  day:Int! 
  hasDetails:Boolean@default(value:"true")
  onMySchedule:Boolean@default(value:"false")
  sessionDescription:String
  sessionLocation:String@relation(name:"AgendaOfMap") #每个 agenda有一个地理位置
  sessionSlug: String
  sessionTitle:String!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Speaker {
  id: ID! @unique
  speakerPic: String
  speakerName: String!
  speakerTitle:String!
  createdAt: DateTime!
  updatedAt: DateTime!
  agendas:[Agenda]@relation(name:"AgendaBySpeaker")  #一个发言者可以有多个 agenda

}

type Map {
  id:ID!@unique
  x1:String
  x2:String
  x3:String
  name:String 
  createdAt: DateTime!
  updatedAt: DateTime!
  mapOfagendas:[Agenda!]@relation(name:"AgendaOfMap") # 一个地图可以有多个 agenda
}

type Faq {
  id:ID!@unique
  question:String
  anwser:String
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Notification {
  id:ID!@unique
  text:String!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Page {
  id:ID!@unique
  alias: String
  title:String
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Todo {
   id:ID!@unique
   createdAt: DateTime!
   updatedAt: DateTime!
   text: String
   isCompleted:Boolean@default(value:"false")
}

type Tag {
id:ID!@unique
   createdAt: DateTime!
   updatedAt: DateTime!
   text: String
   description:String
   agenda:Agenda
  }

```


