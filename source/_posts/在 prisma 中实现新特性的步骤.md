---
title: Prisma 实现新特性的步骤
date: 2018-02-08 21:11:39
categories: 技术备忘
tags: [Graphcool,Prisma]
---
1. Adjust data model (if necessary)
2. Deploy Prisma database service to apply changes to data model (if necessary)
3. Add new root field (on the Query, Mutation or Subscription field) to application schema
4. Implement the resolver for the new root field


