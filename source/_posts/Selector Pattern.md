---
title: Selector Pattern:painless Redux Store Destructiong
date: Friday, December 7, 2018 at 10:55:42 AM China Standard Time
categories: Medium
tags: [React,Redux]
---

{{TOC}}

[`原文请见`](https://hackernoon.com/selector-pattern-painless-redux-store-destructuring-bfc26b72b9ae)

> 作者 :  Dean Slama Jr

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fxy2suks3jj30go09k777.jpg)
Redux非常好,因为它显式定义了所有可能的 state变化(通过actions),以及如何改变state(通过reducer)--但是组件如何查询store的方法没有.

解决这个问题的方法之一是使用 *Selector Pattern*.  在同一个地方集中处理 与state访问有关的问题,减少代码的复杂度.

- Selector 模式
- 在React组件中的实现
- 提取出 Selector的实现部分
- 执行优化:缓存



### Selector模式

Redux 把应用的 state 集中为全局的state(例如,组件间可以共享 state).  这一点对于减少应用的复杂度非常好. seletor模式解决的问题就是如何从集中的全局 state 获取所需要的值的问题.

对于这个问题,常见的解决办法是通过state的引用来访问state.

```javascript
const thePieceOfStateMyAppNeeds = store.someStateDomain.someProperty[someKey]
```


(译注:这里就是问题的关键点, 每次要从很庞大的单个state中筛选出我们需要的部分.  如果把需要的一部分 state,拷贝出来单独存储,如果下次访问时没有改变,就直接从副本中获取数据.)


问题是,这个方法,需要应用代码知道store的确切结构-如果 store 发生了改变,不得更新所有需要state的部分. 

**selector pattern** 是一个抽象方法使得应用store的查询逻辑标准化. 很简单:对于应用需要访问的每一部分,都定义函数,接收整个store,返回需要的部分(或者衍生出来的部分).

直接跳过 selector模式,让组件自己掌握store情况,尤其是在简单引用下.
`wrong1.js`
```
//这段代码在本文是不提倡的

const thePieceOfStateMyAppNeeds=store.someArrayOfValues
```


我会建议对于应用的所有store查询操作都使用selector模式,不要考虑查询是否复杂. 如果store的实现要考虑重构, 通过使用selector模式,需要更新的对象引用关联更新会讲到最低程度.

###  在 React组件中的实现

```javascript
import React from 'react'
import { connect } from 'react-redux'

import { isLoadingFriends, getFriends } from '../redux/reducer'

import Friend from './Friend'

/**
 * Component
 */
export class FriendsList extends React.Component {
  renderLoading () {
    return ( <div>Loading...</div> )
  }

  renderFriendsList () {
    return (
      <div> 
        { this.props.friends.map(friend => (<Friend friend={friend} />)) }
      </div>
    )
  }

  render () {
    if (this.props.isLoading) {
      return this.renderLoading()
    } else {
      return this.renderFriendsList()
    }
  }
}

/**
 * 把 Redux store 映射到组件props
 */
function mapStateToProps (store) {
  return {
    isLoading: isLoadingFriends(store),
    friends: getFriends(store)
  }
}
```


在`mapStateToProps`函数中,我们只是简单的把`store`传递给对应的selector.这个组件不需要知道selector的具体实现细节,仅仅是返回组件需要的部分或者衍生出的数据.

selectors从根reducer模块中导入

```javascript
import { combineReducers } from 'redux'

import userReducer, * as FromUser from './user'
import friendsReducer, * as FromFriends from './friends'

const USER = 'USER'
const FRIENDS = 'FRIENDS'

// -----------------------------------------------------------------------------
// REDUCER

export default const rootReducer = combineReducers({
  [USER]: userReducer,
  [FRIENDS]: friendsReducer
});

// -----------------------------------------------------------------------------
// PUBLIC SELECTORS

// user
export function isLoadingUser(store) {
  return FromUser.isLoading(store[USER]);
}

export function getUsername(store) {
  return FromUser.getUsername(store[USER]);
}

// friends
export function isLoadingFriends(store) {
  return FromFriends.isLoading(store[FRIENDS]);
}

export function getFriends(store) {
  return FromFriends.getFriends(store[FRIENDS]);
}
```

在根 reducer模块中包含 selectors是有意义的,因为 selectors需要知道 应用的整个store的结构.这个模块就是就包含了store的所有情况. 重要的是,如果 store的整体结构发生变化,极有可能只需要修改这一个文件.

selectors共享相同的接口: 都把整个store作为函数的第一个参数. 为了获取需要的值, 这些selectors函数都由一个或者多个私有selector组合而成.公共的 selector 需要整个store作为参数, 每个私有的 selector需要store的一个分支部分.

每个私有的selector和整个 Store 的一个分支相关,方法和reducer从store获取对应的片段是同样的. 更重的是,私有的selectors 和reducers配置可以简单优雅的放在同一个文件中:

```javascript
const defaultStore = {
  isLoading: false,
  friends: []  
}

// -----------------------------------------------------------------------------
// REDUCER

export default const reducer = () => Object.assign({}, defaultStore)



// -----------------------------------------------------------------------------
// 私有SELECTORS

export function isLoadingFriends (store) {
  return store.isLoading
}

export function getFriends (store) {
  return store.friends
}
```


这样的共有/私有selectors模式可以执行:

1. 针对 reducer 变化的配置不需要让共有selector发生改变
2. 两个或者更多的公共selectors可以共享私有的 selector,更容易维护(这里的公有指的是几个组件都需要的 state 部分).

### 衍生selector的实现



