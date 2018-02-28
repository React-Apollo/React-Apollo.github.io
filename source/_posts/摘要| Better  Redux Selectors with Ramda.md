---
title: 摘要|Better Redux Selectors with Ramda
date: 2018-02-28 09:55:17
categories: 技术备忘
tags: [React,Redux,Ramda,FP]
---
>[`原文`](https://medium.com/@grrttn/better-redux-selectors-with-ramda-c1ab7af3f16)

## 目标
目标是把Redux中selector:

```js
export const getUserName = state => state.user.name

export const isLoggedIn = state => state.user.id != null

export const getTotalItemCount = state =>
    Object.values(state.items.byId)
        .reduce((total, item) => total + item.count, 0)
```

转换为:

```js
import R from 'ramda'

// Helper functions
const isNotNil = R.complement(R.isNil)
const pathIsNotNil = path => R.compose(isNotNil, R.path(path))
const addProp = propName => R.useWith(R.add, [R.identity, R.prop(propName)])
const sumProps = propName => R.reduce(addProp(propName), 0)
const sumCounts = sumProps('count')

// Selector functions
export const getUserName = R.path(['user', 'name'])
export const isLoggedIn = pathIsNotNil(['user', 'id'])
export const getTotalItemCount =
    R.compose(sumCounts, R.values, R.path(['items', 'byId']))
```

## 介绍
### Selector函数回顾

`selector` 的概念在 Redux 的文档中出现过,  为了代替直接在 React 组件中访问 state tree,可以定义从 state 获取数据的函数. 可以认为是`从 state获取数据的 API`. 不是必须的, 甚至 Redux也不是一定要用. 

`Selector`函数接收 Redux的 state 对象作为参数, 返回任何你需要的数据. 实例:

`从 State tree 获取 属性`

``` js
function getUserName(state) {
    return state.user.name
}
```

`从属性衍生数据`

```js
function isLoggedIn(state) {
    return state.user.id != null
}
```

`从一个列表数据中衍生数据`

```js
function getTotalItemCount(state) {
    return Object.keys(state.items.byId)
        .reduce(function(total, id) {
            return total + state.items.byId[id].count
        }, 0)
}
```

假定列表的每个 item都有一个`count`属性, 这个 selector 使用`array.reduce()`函数计算`count`的综合. 


```js

export function getUserName(state) {
    return state.user.name
}

export function isLoggedIn(state) {
    return state.user.id != null
}

export function getTotalItemCount(state) {
    return Object.keys(state.items.byId)
        .reduce(function(total, id) {
            return total + state.items.byId[id].count
        }, 0)
}
```

如果使用 ES2015语法,会更简洁

```js
export const getUserName = state => state.user.name

export const isLoggedIn = state => state.user.id != null

export const getTotalItemCount = state =>
    Object.values(state.items.byId)
        .reduce((total, item) => total + item.count, 0)
```
Object.values 是 ES2017的语法

### Ramda 的原则

- 自动柯理化
- 数据最后传入


## 使用 Ramda编写 Selectors
### getUserName

```js
export const getUserName = state => R.path(['user', 'name'], state)
```

改为柯理化的版本:

```js
export const getUserName = state => R.path(['user', 'name'])(state)
```

就可以等待数据了

```js
export const getUserName = R.path(['user', 'name'])
```


这里的函数就看不到数据了, 这个技术被称为 point-free style 或者tacit programming.

### isLoggedIn
我们想要的版本是获取用于的 ID, 然后判断是否为 true

```js
export const isLoggedIn = pathIsNotNullOrUndefined(['user', 'id'])
```

Ramda的 isNil 方法
```js
R.isNil(null) // true
R.isNil(undefined) // true
R.isNil(false) // false
```

现在可以改为:

```js
const isNotNil = val => !R.isNil(val)
```

在更进一步:

```js
const isNotNil = val => R.not(R.isNil(val))
```

另一个方法:

```js
const isNotNil = R.complement(R.isNil)

isNotNil(true) // true
isNotNil(null) // false
isNotNil(undefined) // false
```


进一步重构的版本:

```
const pathIsNotNil = (path, state) => isNotNil(R.path(path, state))

//⛔️柯理化的版本

const pathIsNotNil = path => state => isNotNil(R.path(path, state))
```


`也就是从一个 state获取嵌套属性,并且判断是否为 true`, 由于属性的路径是在 default 中已经配置好的, 所以我们可以使用柯理化提前配置获取的方法, 等待变化的 state 数据.  这就配置出了一个处理 state 的工厂.  为什么柯理化在函数式编程中很重要,这就是原因. 配置出的工厂是与数据独立的, 这就是上面提到的 tacit programming 无参数编程,  函数的配置和传入的参数是无关的, 顶多是对参数的类型做出约束. 

在使用 R.compose 做重构

```js

const pathIsNotNil = path => state => R.compose(isNotNil, R.path)(path, state)
```

整个操作和path,state 有关,  通过 path从 state 获取属性, 然后判断是否为 true,

```js
const pathIsNotNil = path => state => R.compose(isNotNil, R.path(path))(state)
//👇👇柯理化

const pathIsNotNil = path => R.compose(isNotNil, R.path(path))
```

在 pathIsNotNil中实际的数据只有 state,path 是属于配置项, 也就是在程序中是不改变的.

```js
export const isLoggedIn = pathIsNotNil(['user', 'id'])

//配置了从对象的路径 user.id 获取属性值,然后判断是否为 true
```


### getTotalItemCount

//刚开始的方法
```js
export const getTotalItemCount = state =>
    Object.values(state.items.byId)
        .reduce((total, item) => total + item.count, 0)
```

面对复杂的问题, 使用函数式风格进行分解是比较好的选择.创建一个函数`sumCounts`,接收一个数组, 返回项目中`count`属性的总计.  

```js
const sumCounts = items =>
    items.reduce((total, item) => total + item.count, 0)
```


#### 使用 map

```js
const sumCounts = R.compose(R.sum, R.map(R.prop('count')))
```

R.map 对数组的每一项调用 R.prop('count')函数, 获取的`所有count 属性`,放到一个新的数组中, 之后用 R.sum 对数组中的属性值做合计

Ramda 针对map 这个函数的使用,也有更简单的方法

```js
const sumCounts = R.compose(R.sum, R.pluck('count'))
```

R.pluck 从数组中获取每一项的属性值


### 使用 Reduce 函数的替代方案

```js
const sumCounts = R.reduce((total, item) => total + item.count, 0)
```


```js
const addCount=(total,item)=>total+item.count
const sumCounts = R.reduce(addCount, 0)
```

 使用 Ramda 的 R.add 方法
 
```js
 const addCount = (total, item) => R.add(total, item.count)
```

从对象中获取属性

```js
const addCount = (total, item) => R.add(total, prop('count', item))

// 柯理化形式
const addCount = (total, item) => R.add(total, prop('count')(item))
```

上面的函数通用的模式是: 接收两个参数,传递给另一个函数, 第一个参数不懂, 对第二个参数运用一个函数进行处理,之后再执行第一个函数

Ramda 有一个函数可以帮我们完成这个任务, `useWith`, 
`useWith`函数接收两个参数, 第一个参数是单个的函数,和一个函数数组. 数组中的函数被称为变换函数-在对应位置的参数被第一个函数调用之前进行变换处理. 换句话说,数组的第一个函数对第一个参数进行处理, 第二个函数对第二个参数进行处理,以此类推.转换后的参数传递个第一个参数的函数. 

在我们的实例中,第一个参数的函数 R.add, 

```js
const addCount = R.useWith(R.add, [/* transformers */])
```

需要对 R.add 的第二个参数进行处理, 从 `count`属性中获取值, 所以放在第二个函数的位置

```js
const addCount = R.useWith(R.add [/* 1st */, R.prop('count')])
```

第一个参数怎么办? 这个参数对应的是 total 值, 不需要转换 , Ramda有一个函数可以原封不动的返回一个数值, R.identity. 

```js
const addCount = R.useWith(R.add, [R.identity, R.prop('count')])
```

现在的函数:

```js
const addCount = R.useWith(R.add, [R.identity, R.prop('count')])

const sumCounts = R.reduce(addCount, 0)
```


现在可以获得更为通用的方式,获取任意的属性, 

```js
const addProp = propName => R.useWith(R.add, [R.identity, R.prop(propName)])

const sumProps = propName => R.reduce(addProp(propName), 0)

const sumCounts = sumProps('count')
```

参数的转换方式也可以抽象出来:

```js
const addTransformedItem = transformer =>
    R.useWith(R.add, [R.identity, transformer])

const sumTransformedItems = transformer =>
    R.reduce(addTransformedItem(transformer), 0)

const totalItemComments = R.compose(R.length, R.prop('comments'))

const sumComments = sumTransformedItems(totalItemComments)
```


最终在 Ramda 的帮助下, 总的数据获取流是有更小的可以重用的函数组成的..

### 结构

如果有下面的数据

```js
const state = {
    items: {
        byId: {
            'item1': { id: 'item1', count: 2 },
            'item2': { id: 'item2', count: 4 },
            'item3': { id: 'item3', count: 7 }
        }
    }
}
```

```js
export const getTotalItemCount =
    R.compose(sumCounts, R.values, R.path(['items', 'byId']))
```
最终得到的结果
``` js
mport R from 'ramda'

// Helper functions
const isNotNil = R.complement(R.isNil)
const pathIsNotNil = path => R.compose(isNotNil, R.path(path))
const addProp = propName => R.useWith(R.add, [R.identity, R.prop(propName)])
const sumProps = propName => R.reduce(addProp(propName), 0)
const sumCounts = sumProps('count')

// Selector functions
export const getUserName = R.path(['user', 'name'])
export const isLoggedIn = pathIsNotNil(['user', 'id'])
export const getTotalItemCount =
    R.compose(sumCounts, R.values, R.path(['items', 'byId']))
```



**`函数式编程最好的解释应该是: 数据和要对数据进行操作的函数式分离开的`**.  基于此, 就可以发现,  React的组件也可以看成一个函数, 接收应用的数据, 对数据进行处理,之后进行渲染.   







