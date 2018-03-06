---
title: Prisma|Native Authenticate Method
date: 2018-03-06 22:18:42
categories: 技术备忘
tags: [GraphQL,Prisma]
---

针对以下的 schema
```
type Query {
  vehicles(dealership: ID!): [Vehicle!]!
}

type Mutation {
  updateVehicleAskingPrice(id: ID!, askingPrice: Int!): Vehicle
}

type Vehicle {
  id: ID!
  year: Int!
  make: String!
  model: Int!
  askingPrice: Float
  costBasis: Float
  numberOfOffers: Int
}

type User {
  id: ID!
  name: String!
  role: String!
}
```


- `updataVehicleAskingPrice`应该只能有管理员操作
- `costBasis`: 仅限于管理员
- `numberOfOffers`: 认证用户可以使用

```
const Mutation = {
  updateVehicleAskingPrice: async (parent, { id, askingPrice }, context, info) => {
    const userId = getUserId(context)
    //用户的 role进行查询,看看是否数据管
    const isRequestingUserManager = await context.db.exists.User({
      id: userId,
      role: `MANAGER`
    })
    if (isRequestingUserManager) {
      return await context.db.mutation.updateVehicle({
        where: { id },
        data: { askingPrice }
      })
    }
    throw new Error(
        `Invalid permissions, you must be a manager to update vehicle year`
    )
  }
}
```
使用`exists`函数. 


字段级别的认证

```js
const Query = {
  vehicles: async (parent, args, context, info) => {
    const vehicles = await context.db.query.vehicles({
      where: { dealership: args.id }
    })
    const user = getUser(context)

    return vehicles.map(vehicle => ({
      ...vehicle,
      costBasis:
          user && user.role.includes(`MANAGER`) ? vehicle.costBasis : null,
      numberOfOffers: user ? vehicle.numberOfOffers : null
    }))
  }
}
```

