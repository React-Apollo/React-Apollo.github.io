---
title: React,Reselect and Redux
date: Friday, December 7, 2018 at 9:19:24 AM China Standard Time
categories: Medium
tags: [React,Redux,Reselect]
---

[` 原文在这里`](https://medium.com/@parkerdan/react-reselect-and-redux-b34017f8194c)

> 作者 :  Dan Parker

{{TOC}}

(译注: 主要思想实际和Node.js的中间件类似,在 UI 组件从Redux的 State 中获取对象分枝时,不要在UI组件中对数据进行复杂处理,在 UI 组件之前再加一个 Reselect的selector(同样可以把单个的selector组合起来,形成更为复杂的数据结构),在selector中进行数据的复杂处理,或者是缓存处理, UI组件要完全成为无状态的. `提起出数据选取,处理和缓存组件.`)

React很棒, Redux很棒,Reselect 也很棒.但是要让三个部分一起工作还是要有点技巧的. 我会试着解释讲解一下三者如何一起配合工作.

`npm install --save reselect`

如果你还没有React,Redux以及 Redux-connect(Redux连接组件)的知识,就暂时不要往下继续了,等学完了上面三个知识以后再返回来继续学习.


## Reselect创建了有记忆能力的选择器(selector),并且把选择器组合起来
(译注:因为没有恰当的译文,所以下面仍然直接使用英文单词,并注意单复数变化,单数指从 Redux 的 state 对象中选出的单个对象分支,复数值得是单个对象分支的组合)
是滴,这就是需要技巧的地方. Selector 的 Selectors.  Selector 的意义. 

可以直接到本文最后查看源代码.

第一步:创建selector...可以在connect 文件中创建.但是现在我们创建单独的文件 

`selector.js`

```javascript
const getBar=(state)=>state.foo.bar
```

这样,一个简单的selector就完成了,但是这和 Reselect没有什么关系. 在 Redux 的 connect 方法中都是这么做的,不同点只是这是单独创建了一个文件. 只要`getBar()`函数获得state对象,总是返回 `state.foo.bar`
(译注:这是函数式编程的概念,同样的输入,总是有同样的输出).


## 现在Reselect可以出场了.

Reselect是记忆性的reselector函数,组合selectors,之后返回组件需要的属性(React Props).

```javascript
import {createSelector} from 'reselect';
//selector

const getBar=state=>state.foo.bar;

//reselect function

export const getBarState=createSelector(
   [getBar],
   (bar)=>bar
)
```

我知道这段代码初看起来有点滑稽.但是这里发生了很多事.`createSelector`是一个函数.第一个参数是一个selectors. 第二个参数的参数就是 reselectors.
所以,上面 `(bar)=>bar`是一个函数.这个函数只有一个参数(这里我命名为bar,但是你可以用任何函数名),就是selectors,也就是第一个参数声明的 `createSelector`函数.

仍然有点令人费解...我明白. 坚持往下面看,你会明白的. 当这个文件和`mapStateToProps`放到一起的时候,就有意义了.

## React 组件

```javascript
import React from 'react';
import {connect} from 'react-redux';
import {getBarState} from '../selectors'

const mapStateToProps=(state)=>{
   return {
      bar:getBarState(state)
   }
}

class Thing extends React.component {
    ...
}

export default connect(mapStateToProps)(Thing)
```


看到了吗? 很标准的 Redux配置,唯一不同点是我们用了selector函数,而没有直接用`state.foo.bar`对象分支.

我们把`state`传递进`getBarState`函数

`getBar`函数调用 `getBar`函数,`state`作为参数.

`getBar`函数获取 state对象,返回 bar.

我们在 Reselect函数中使用了返回的值.

Reselect处理了数据的记忆(或者缓存).

**注意:在使用 Redux 时,无论应用中分发任何action,所有的mount和connect 组件都会调用他们的 mapStateToProps函数. 这就是 Reselect非常酷的地方.如果没有发生变化,它只返回记忆的结果**
(译注:注意 React的组件props更新的问题).

## 高级使用方法

在实际使用中,可能不同的组件需要的是相同的state部分.所以也想把同样的 props 传递给selector. 为了实现这个步骤,需要创建可以同时在多个组件中使用的selector函数...所有的内容都会被记忆.

为了让有相应记忆的`selectorFunction` 函数可以重用.就不能用单个组件的方法来写了. `mapStateToProps`也必须要修改.

**如果多个组件需要使用同一个记忆reselector,需要在每次使用时都创建实例**.

把`selectorFunction`修改为匿名函数(anonymouse function), 返回 一个`selectorFunction`.


```javascript
import {createSelector} from 'reselect'
//我以一个通用的selector,我不需要特殊待遇
//我现在有了 props,所以我可以扎到特定的 bar 分支了


const getBar=(state,props)=>{
  const id=props.id
  const barById=state.foo.bar.find((item,i)=>item.id===id)
  return barByID
}

//如果在多个组件中需要这个分支,就不能工作了
//export const getBarState=createSelector(
   //[getBar],
   //(bar)=>bar
//)


//如果要在多个组件中使用这个属性,这是正确的用法

export const makeGetBarStaet=()=>createSelector(
   [getBar],
   (bar)=>bar
)
```


现在,当我们调用`makeGetBarState`,就可以得到一个`createSelector`函数.

在组件中使用时也必须要做一些改动


```javascript
import React from 'react'
import { connect } from 'react-redux'
import { makeGetBarState } from '../selectors'
// remember, mapStateToProps can have the component's
// props as the second argument
// but now we need to modify this method to allow for a new
// instance of our makeGetBarState function, which returns a 
// memoized selector 
const makeMapStateToProps = () => {
 const getBarState = makeGetBarState()
 const mapStateToProps = (state, props) => {
   return {
      bar: getBarState(state, props)
   }
  }
 return mapStateToProps
}
class Thing extends React.Component {
  ...
}
export default connect(makeMapStateToProps)(Thing)
```


我们需要把 mapStateToProps改为匿名函数,它返回一个 mapStateToProps函数...因此命名为`makeMapStateToProps`,

在`makeMapStateToProps`中, 我使用`const getBarState=makeGetBarState()`创建了一个selector函数的实例.

现在`getBarState`就是一个 selector函数了, 和其他的selector没有相互关联(independent). 可以在多个组件中使用.

(译注:如果要了解底层,这里就是JavaScript的高阶函数, 高阶函数的底层就是 JavaScript的闭包,创建函数实例时,为每个组件都出创建了单独的变量空间,这就是 independent的含义).

### 清理一下

大家都喜欢简短和甜蜜... 对吧.  为了简洁,可以重构一下代码.


`selector.js`

```javascript
import { createSelector } from 'reselect'
const getBar = (state, props) => state.foo.bar.find( b => b.id === props.id )
export const makeGetBarState = () => createSelector(
  getBar,
  (bar) => ({ bar })
)
```


`component`

```javascript
import React from 'react'
import { connect } from 'react-redux'
import { makeGetBarState } from '../selectors'
const makeMapStateToProps = () => {
  const getBarState = makeGetBarState()
  return (state, props) => getBarState(state, props)
}
class Thing extends React.Component {
 ...
}
export default connect(makeMapStateToProps)(Thing)
```


[代码在这里](https://github.com/reactjs/reselect#createselectorinputselectors--inputselectors-resultfunc)

