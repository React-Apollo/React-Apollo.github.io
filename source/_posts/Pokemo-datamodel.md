---
title: PokeMon datamodel
date:  2018-03-16 10:04:10
categories: 技术备忘
tags: [GraphQL, datamodel]
---

```gql
type Trainer {
  id: String!
  name: String!
  ownedPokemons: [Pokemon] # 一个训练师有多个宠物
}

type Pokemon {
  id: String!
  url: String!
  name: String!
  trainer: Trainer # 一个宠物属于一个训练师
}
```

基础查询 

```gql
const TrainerQuery = gql`
  query TrainerQuery($name: String!) {
    Trainer(name: $name) {
      id
      name
      ownedPokemons {
        id
        name
        url
      }
    }
  }
`
```

ownedPokeMons是一个数组,可以用`Trainer.ownedPokemons.length`,获取到训练师所有的宠物的数量.

宠物详情查询

```gql
const PokemonQuery = gql`
  query PokemonQuery($id: ID!) {
    Pokemon(id: $id) {
      id
      url
      name
    }
  }
`
```


