---
title: 重新翻译版本|Redux-Reselect 文档
date: Friday, December 7, 2018 at 2:19:47 PM China Standard Time
categories: 技术备忘
tags: [React,Redux]
---

{{TOC}}


> “selector”是一个简单的Redux库,灵感来源于`NuclearJS`.

- Selector可以计算衍生的数据,可以让Redux做到存储尽可能少的state。
- Selector比较高效,只有在某个参数发生变化的时候才发生计算过程.
- Selector是可以组合的,他们可以作为输入,传递到其他的selector.

```js
//这个例子不必太在意,后面会有详细的介绍
import { createSelector } from 'reselect'

const shopItemsSelector = state => state.shop.items
const taxPercentSelector = state => state.shop.taxPercent

const subtotalSelector = createSelector(
  shopItemsSelector,
  items => items.reduce((acc, item) => acc + item.value, 0)
)

const taxSelector = createSelector(
  subtotalSelector,
  taxPercentSelector,
  (subtotal, taxPercent) => subtotal * (taxPercent / 100)
)

export const totalSelector = createSelector(
  subtotalSelector,
  taxSelector,
  (subtotal, tax) => ({ total: subtotal + tax })
)

let exampleState = {
  shop: {
    taxPercent: 8,
    items: [
      { name: 'apple', value: 1.20 },
      { name: 'orange', value: 0.95 },
    ]
  }
}

console.log(subtotalSelector(exampleState)) // 2.15
console.log(taxSelector(exampleState))      // 0.172
console.log(totalSelector(exampleState))    // { total: 2.322 }
```


## Table of Contents

- [Installation](#安装)
- [实例](#实例)
  - [Motivation for Memoized Selectors](#motivation-for-memoized-selectors)
  - [Creating a Memoized Selector](#creating-a-memoized-selector)
  - [Composing Selectors](#composing-selectors)
  - [Connecting a Selector to the Redux Store](#connecting-a-selector-to-the-redux-store)
  - [Accessing React Props in Selectors](#accessing-react-props-in-selectors)
  - [Sharing Selectors with Props Across Multiple Components](#sharing-selectors-with-props-across-multiple-components)
- [API](#api)
  - [`createSelector`](#createselectorinputselectors--inputselectors-resultfunc)
  - [`defaultMemoize`](#defaultmemoizefunc-equalitycheck--defaultequalitycheck)
  - [`createSelectorCreator`](#createselectorcreatormemoize-memoizeoptions)
  - [`createStructuredSelector`](#createstructuredselectorinputselectors-selectorcreator--createselector)
- [FAQ](#faq)
  - [Why isn't my selector recomputing when the input state changes?](#q-why-isnt-my-selector-recomputing-when-the-input-state-changes)
  - [Why is my selector recomputing when the input state stays the same?](#q-why-is-my-selector-recomputing-when-the-input-state-stays-the-same)
  - [Can I use Reselect without Redux?](#q-can-i-use-reselect-without-redux)
  - [The default memoization function is no good, can I use a different one?](#q-the-default-memoization-function-is-no-good-can-i-use-a-different-one)
  - [How do I test a selector?](#q-how-do-i-test-a-selector)
  - [How do I create a selector that takes an argument? ](#q-how-do-i-create-a-selector-that-takes-an-argument)
  - [How do I use Reselect with Immutable.js?](#q-how-do-i-use-reselect-with-immutablejs)
  - [Can I share a selector across multiple components?](#q-can-i-share-a-selector-across-multiple-components)
  - [Are there TypeScript typings?](#q-are-there-typescript-typings)
  - [How can I make a curried selector?](#q-how-can-i-make-a-curried-selector)

- [Related Projects](#related-projects)
- [License](#license)

## 安装
`npm install reselect`

## 实例

### 缓存Selcectos的动机

> 实例是基于 [Redux Todos List example](http://redux.js.org/docs/basics/UsageWithReact.html).

`containers/VisibleTodoList.js`
```js
import { connect } from 'react-redux'
import { toggleTodo } from '../actions'
import TodoList from '../components/TodoList'

//下面这段代码是根据过滤器的state来改变日程state的函数
const getVisibleTodos = (todos, filter) => {
  switch (filter) {
    case 'SHOW_ALL':
      return todos
    case 'SHOW_COMPLETED':
      return todos.filter(t => t.completed)
    case 'SHOW_ACTIVE':
      return todos.filter(t => !t.completed)
  }
}

const mapStateToProps = (state) => {
  return {
    //todos是根据过滤函数返回的state，传入两个实参
    todos: getVisibleTodos(state.todos, state.visibilityFilter)
  }
}
//mapDispatchToProps来传递dispatch的方法
const mapDispatchToProps = (dispatch) => {
  return {
    onTodoClick: (id) => {
      dispatch(toggleTodo(id))
    }
  }
}
//使用Redux的connect函数注入state,到TodoList组件
const VisibleTodoList = connect(
  mapStateToProps,
  mapDispatchToProps
)(TodoList)

export default VisibleTodoList
```

在上面的例子中,`mapStateToProps`调用`getVisibleTodos`去计算`todos`.这个函数设计的是相当好的,但是有个缺点：`todos`在每一次组件更新的时候都会重新计算.如果state树的结构比较大,或者计算比较昂贵,每一次组件更新的时候都进行计算的话,将会导致性能问题.`Reselect`能够帮助redux避免不必要的计算过程.

### 创建一个缓存Selector
我们可以使用记忆缓存selector代替`getVisibleTodos`,如果`state.todos`和`state.visibilityFilter`发生变化,他会重新计算`state`,但是只发生在其他部分的state变化,就不会重新计算.

Reslect提供一个函数`createSelector`来创建一个记忆selectors.`createSelector`接受`input-selectors`和一个变换函数作为参数.如果Redux的state发生改变造成`input-selector`的值发生改变,selector会调用变换函数,依据`input-selector`做参数,返回一个结果.如果`input-selector`返回的结果和前面的一样,那么就会直接返回有关state,会省略变换函数的调用.

下面我们定义一个记忆selector`getVisibleTodos`替代非记忆的版本

 `selectors/index.js`

```js
import { createSelector } from 'reselect'

const getVisibilityFilter = (state) => state.visibilityFilter
const getTodos = (state) => state.todos
//下面的函数是经过包装的
export const getVisibleTodos = createSelector(
  [ getVisibilityFilter, getTodos ],
  (visibilityFilter, todos) => {
    switch (visibilityFilter) {
      case 'SHOW_ALL':
        return todos
      case 'SHOW_COMPLETED':
        return todos.filter(t => t.completed)
      case 'SHOW_ACTIVE':
        return todos.filter(t => !t.completed)
    }
  }
)
```
___
上面的的实例中,`getVisibilityfilter`和`getTodos`是input-selectors.这两个函数是普通的非记忆selector函数,因为他们没有变换他们select的数据.`getVisibleTodos`另一方面是一个记忆selector.他接收`getVisibilityfilter`和`getTodos`作为input-selectors,并且作为一个变换函数计算筛选的todo list.

### 组合selectors

一个记忆性selector本身也可以作为另一个记忆性selector的input-selector.这里`getVisibleTodos`可以作为input-selector作为关键字筛选的input-selector:
```js
const getKeyword = (state) => state.keyword

const getVisibleTodosFilteredByKeyword = createSelector(
  [ getVisibleTodos, getKeyword ],
  (visibleTodos, keyword) => visibleTodos.filter(
    todo => todo.text.indexOf(keyword) > -1
  )
)
```

###  把Selector连接到Redux Store
如果你正在使用 [React Redux](https://github.com/reactjs/react-redux), 你可以 直接在`mapStateToProps()`中调用 selector:

 `containers/VisibleTodoList.js`

```js
import { connect } from 'react-redux'
import { toggleTodo } from '../actions'
import TodoList from '../components/TodoList'
import { getVisibleTodos } from '../selectors'

const mapStateToProps = (state) => {
  return {
    todos: getVisibleTodos(state)
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onTodoClick: (id) => {
      dispatch(toggleTodo(id))
    }
  }
}

const VisibleTodoList = connect(
  mapStateToProps,
  mapDispatchToProps
)(TodoList)

export default VisibleTodoList
```


### 在Selectors中获取 React 的 props

>这一部分我们假设程序将会有一个扩展,我们允许selector支持多重todo List.请注意如果要完全实施这个扩展,reducers,components,actions等等都需要作出改变.这些内容和主题不是太相关,所以这里就省略掉了.

目前为止,我们仅仅看到selectors接收store的state作为一个参数,其实一个selector叶可以接受props.

这里是一个`App`组件,渲染出三个`VisibleTodoList`组件,每一个组件有`ListId`属性.

 `components/App.js`

```js
import React from 'react'
import Footer from './Footer'
import AddTodo from '../containers/AddTodo'
import VisibleTodoList from '../containers/VisibleTodoList'

const App = () => (
  <div>
    <VisibleTodoList listId="1" />
    <VisibleTodoList listId="2" />
    <VisibleTodoList listId="3" />
  </div>
)
```


每一个`VisibleTodoList`container应该根据各自的`listId`属性获取state的不同部分.所以我们修改一下`getVisibilityFilter`和`getTodos`,便于接受一个属性参数

#### `selectors/todoSelectors.js`

```js
import { createSelector } from 'reselect'

const getVisibilityFilter = (state, props) =>
  state.todoLists[props.listId].visibilityFilter

const getTodos = (state, props) =>
  state.todoLists[props.listId].todos //这里是为二维数组了

const getVisibleTodos = createSelector(
  [ getVisibilityFilter, getTodos ],
  (visibilityFilter, todos) => {
    switch (visibilityFilter) {
      case 'SHOW_COMPLETED':
        return todos.filter(todo => todo.completed)
      case 'SHOW_ACTIVE':
        return todos.filter(todo => !todo.completed)
      default:
        return todos
    }
  }
)

export default getVisibleTodos
```

`props`可以从`mapStateToProps`传递到`getVisibleTodos`：

```js
const mapStateToProps = (state, props) => {
  return {
    todos: getVisibleTodos(state, props)
  }
}
```

现在`getVisibleTodos`可以获取`props`,每一部分似乎都工作的不错.

***但是还有个问题!*
当`getVisibleTodos`selector和`VisibleTodoList`container的多个实例一起工作的时候,记忆功能就不能正常运行:

 `containers/VisibleTodoList.js`

```js
import { connect } from 'react-redux'
import { toggleTodo } from '../actions'
import TodoList from '../components/TodoList'
import { getVisibleTodos } from '../selectors'

const mapStateToProps = (state, props) => {
  return {
    // WARNING: THE FOLLOWING SELECTOR DOES NOT CORRECTLY MEMOIZE
    //⚠️下面的selector不能正确的记忆
    todos: getVisibleTodos(state, props)
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onTodoClick: (id) => {
      dispatch(toggleTodo(id))
    }
  }
}

const VisibleTodoList = connect(
  mapStateToProps,
  mapDispatchToProps
)(TodoList)

export default VisibleTodoList
```


使用`createSelector`创建的selector时候,如果他的参数集合和上一次的参数机会是一样的,仅仅返回缓存的值.如果我们交替渲染`<VisibleTodoList listId="1" />` 和` <VisibleTodoList listId="2" />`时,共享的selector将会交替接受`{listId：1}`和`{listId:2}`作为他的props的参数.这将会导致每一次调用的时候的参数都不同,因此selector每次都会重新来计算而不是返回缓存的值.下一部分我们将会介绍怎么解决这个问题.

### 跨越多个组件使用selectors共享props

>这一部分的实例需要React Redux v4.3.0或者更高版本的支持.

在多个`VisibleTodoList`组件中共享selector,同时还要**保持**记忆性,每一个组件的实例需要他们自己的selector私有拷贝.

现在让我们创建一个函数`makeGetVisibleTodos`,这个函数每次调用的时候返回一个新的`getVisibleTodos`的拷贝:

 `selectors/todoSelectors.js`

```js
import { createSelector } from 'reselect'

const getVisibilityFilter = (state, props) =>
  state.todoLists[props.listId].visibilityFilter

const getTodos = (state, props) =>
  state.todoLists[props.listId].todos

const makeGetVisibleTodos = () => {
  return createSelector(
    [ getVisibilityFilter, getTodos ],
    (visibilityFilter, todos) => {
      switch (visibilityFilter) {
        case 'SHOW_COMPLETED':
          return todos.filter(todo => todo.completed)
        case 'SHOW_ACTIVE':
          return todos.filter(todo => !todo.completed)
        default:
          return todos
      }
    }
  )
}

export default makeGetVisibleTodos
```

我们也需要设置给每一个组件的实例他们各自获取私有的selector方法.`mapStateToProps`的`connect`函数可以帮助完成这个功能.

如果`mapStateToProps`提供给`connect`的不是一个对形象,而是一个函数,每个`container`中就会创建独立的`mapStateToProps`实例. 

在下面的实例中,`mapStateProps`创建一个新的`getVisibleTodos`selector,他返回一个`mapStateToProps`函数,这个函数能够接入新的selector.

```js
const makeMapStateToProps = () => {
  const getVisibleTodos = makeGetVisibleTodos()
  const mapStateToProps = (state, props) => {
    return {
      todos: getVisibleTodos(state, props)
    }
  }
  return mapStateToProps
}
```

如果我们把`makeMapStateToprops`传递到`connect`,每一个`visibleTodoList`container将会获得各自的含有私有`getVisibleTodos`selector的`mapStateToProps`函数.这样一来记忆就正常了,不管`VisibleTodoList`containers的渲染顺序怎么样.

 `containers/VisibleTodoList.js`

```js
import { connect } from 'react-redux'
import { toggleTodo } from '../actions'
import TodoList from '../components/TodoList'
import { makeGetVisibleTodos } from '../selectors'

const makeMapStateToProps = () => {
  const getVisibleTodos = makeGetVisibleTodos()
  const mapStateToProps = (state, props) => {
    return {
      todos: getVisibleTodos(state, props)
    }
  }
  return mapStateToProps
}

const mapDispatchToProps = (dispatch) => {
  return {
    onTodoClick: (id) => {
      dispatch(toggleTodo(id))
    }
  }
}

const VisibleTodoList = connect(
  makeMapStateToProps,
  mapDispatchToProps
)(TodoList)

export default VisibleTodoList
```
___

## API
### createSelector(…inputSelectors|[inputSelectors],resultFunc)

接受一个或者多个selectors,或者一个selectors数组,计算他们的值并且作为参数传递给`resultFunc`.

`createSelector`通过判断input-selector之前调用和之后调用的返回值的全等于(===,这个地方英文文献叫reference equality,引用等于,这个单词是本质,中文没有翻译出来).经过`createSelector`创建的selector应该是immutable(不变的).

经过`createSelector`创建的Selectors有一个缓存,大小是1.这意味着当一个input-selector变化的时候,他们总是会重新计算state,因为Selector仅仅存储每一个input-selector前一个值.

```js
const mySelector = createSelector(
  state => state.values.value1,
  state => state.values.value2,
  (value1, value2) => value1 + value2
)

// You can also pass an array of selectors
//可以出传递一个selector数组
const totalSelector = createSelector(
  [
    state => state.values.value1,
    state => state.values.value2
  ],
  (value1, value2) => value1 + value2
)
```

在selector内部获取一个组件的props非常有用.当一个selector通过`connect`函数连接到一个组件上,组件的属性作为第二个参数传递给selector:
```js
const abSelector = (state, props) => state.a * props.b

// props only (ignoring state argument)
const cSelector =  (_, props) => props.c

// state only (props argument omitted as not required)
const dSelector = state => state.d

const totalSelector = createSelector(
  abSelector,
  cSelector,
  dSelector,
  (ab, c, d) => ({
    total: ab + c + d
  })
)

```
___

### defaultMemoize(func, equalityCheck = defaultEqualityCheck)

`defaultMemoize`能记住通过func传递的参数.这是`createSelector`使用的记忆函数.

`defaultMemoize` 通过调用`equalityCheck`函数来决定一个参数是否已经发生改变.因为`defaultMemoize`设计出来就是和immutable数据一起使用,默认的`equalityCheck`使用引用全等于来判断变化:

```js
function defaultEqualityCheck(currentVal, previousVal) {
  return currentVal === previousVal
}
```
___
`defaultMemoize`和`createSelectorCreator`去[配置`equalityCheck`函数](#配置-equalitycheck-for-defaultmemoize).


### createSelectorCreator(memoize,…memoizeOptions)

`createSelectorCreator`用来配置定制版本的`createSelector`.

`memoize`参数是一个有记忆功能的函数,来代替`defaultMemoize`.
`…memoizeOption`展开的参数是0或者更多的配置选项,这些参数传递给`memoizeFunc`.selectors`resultFunc`作为第一个参数传递给`memoize`,`memoizeOptions`作为第二个参数:

```js
const customSelectorCreator = createSelectorCreator(
  customMemoize, // function to be used to memoize resultFunc,记忆resultFunc
  option1, // option1 will be passed as second argument to customMemoize 第二个惨呼
  option2, // option2 will be passed as third argument to customMemoize 第三个参数
  option3 // option3 will be passed as fourth argument to customMemoize   第四个参数
)

const customSelector = customSelectorCreator(
  input1,
  input2,
  resultFunc // resultFunc will be passed as first argument to customMemoize  作为第一个参数传递给customMomize
)
```
___

在`customSelecotr`内部滴啊用memoize的函数的代码如下:
```js
customMemoize(resultFunc, option1, option2, option3)
```
___

下面是几个可能会用到的`createSelectorCreator`的实例:

 为`defaultMemoize`配置`equalityCheck`

```js
import { createSelectorCreator, defaultMemoize } from 'reselect'
import isEqual from 'lodash.isEqual'

// create a "selector creator" that uses lodash.isEqual instead of ===
const createDeepEqualSelector = createSelectorCreator(
  defaultMemoize,
  isEqual
)

// use the new "selector creator" to create a selector
const mySelector = createDeepEqualSelector(
  state => state.values.filter(val => val < 5),
  values => values.reduce((acc, val) => acc + val, 0)
)
```

使用loadsh的memoize函数来缓存未绑定的缓存.

```js
import { createSelectorCreator } from 'reselect'
import memoize from 'lodash.memoize'

let called = 0
const hashFn = (...args) => args.reduce(
  (acc, val) => acc + '-' + JSON.stringify(val),
  ''
)
const customSelectorCreator = createSelectorCreator(memoize, hashFn)
const selector = customSelectorCreator(
  state => state.a,
  state => state.b,
  (a, b) => {
    called++
    return a + b
  }
)
```



### createStructuredSelector({inputSelectors}, selectorCreator = createSelector)

如果在普通的模式下使用`createStructuredSelector`函数可以提升便利性.传递到`connect`的selector装饰者(这是js设计模式的概念,可以参考相关的书籍)接受他的input-selectors,并且在一个对象内映射到一个键上.

```js
const mySelectorA = state => state.a
const mySelectorB = state => state.b

// The result function in the following selector
// is simply building an object from the input selectors 由selectors构建的一个对象
const structuredSelector = createSelector(
   mySelectorA,
   mySelectorB,
   mySelectorC,
   (a, b, c) => ({
     a,
     b,
     c
   })
)
```


`createStructuredSelector`接受一个对象,这个对象的属性是input-selectors,函数返回一个结构性的selector.这个结构性的selector返回一个对象,对象的键和`inputSelectors`的参数是相同的,但是使用selectors代替了其中的值.

```js
const mySelectorA = state => state.a
const mySelectorB = state => state.b

const structuredSelector = createStructuredSelector({
  x: mySelectorA,
  y: mySelectorB
})

const result = structuredSelector({ a: 1, b: 2 }) // will produce { x: 1, y: 2 }
```


结构性的selectors可以是嵌套式的:

```js
const nestedSelector = createStructuredSelector({
  subA: createStructuredSelector({
    selectorA,
    selectorB
  }),
  subB: createStructuredSelector({
    selectorC,
    selectorD
  })
})

```

## FAQ

### Q:为什么当输入的state发生改变的时候,selector不重新计算？
A:检查一下你的记忆韩式是不是和你的state更新函数相兼容(例如:如果你正在使用Redux).例如:使用`createSelector`创建的selector总是创建一个新的对象,原来期待的是更新一个已经存在的对象.`createSelector`使用(===)检测输入是否改变,因此如果改变一个已经存在的对象没有触发selector重新计算的原因是改变一个对象的时候没有触发相关的检测.提示：如果你正在使用Redux,改变一个state对象的[错误可能有](http://redux.js.org/docs/Troubleshooting.html).


下面的实例定义了一个selector可以决定数组的第一个todo项目是不是已经被完成:
```js
const isFirstTodoCompleteSelector = createSelector(
  state => state.todos[0],
  todo => todo && todo.completed
)
```
___

下面的state更新函数和`isFirstTodoCompleteSelector`**将不会**正常工作工作:

```js
export default function todos(state = initialState, action) {
  switch (action.type) {
  case COMPLETE_ALL:
    const areAllMarked = state.every(todo => todo.completed)
    // BAD: mutating an existing object
    return state.map(todo => {
      todo.completed = !areAllMarked
      return todo
    })

  default:
    return state
  }
}
```


下面的state更新函数和`isFirstTodoComplete`一起**可以**正常工作.

```js
export default function todos(state = initialState, action) {
  switch (action.type) {
  case COMPLETE_ALL:
    const areAllMarked = state.every(todo => todo.completed)
    // GOOD: returning a new object each time with Object.assign
    return state.map(todo => Object.assign({}, todo, {
      completed: !areAllMarked
    }))

  default:
    return state
  }
}
```


如果你没有使用Redux,但是有使用mutable数据的需求,你可以使用`createSelectorCreator`代替默认的记忆函数,并且使用不同的等值检测函数.请参看[这里](#use-memoize-function-from-lodash-for-an-unbounded-cache) 和 [这里](#customize-equalitycheck-for-defaultmemoize)作为参考.


### Q:为什么input state没有改变的时候,selector还是会重新计算?

A: 检查一下你的记忆函数和你你的state更新函数是不是兼容(如果是使用Redux的时候,看看reducer).例如:使用每一次更新的时候,不管值是不是发生改变,`createSelector`创建的selector总是会收到一个新的对象.`createSelector`函数使用(`===`)检测input的变化,由此可知如果每次都返回一个新对象,表示selector总是在每次更新的时候重新计算.

```js
import { REMOVE_OLD } from '../constants/ActionTypes'

const initialState = [
  {
    text: 'Use Redux',
    completed: false,
    id: 0,
    timestamp: Date.now()
  }
]

export default function todos(state = initialState, action) {
  switch (action.type) {
  case REMOVE_OLD:
    return state.filter(todo => {
      return todo.timestamp + 30 * 24 * 60 * 60 * 1000 > Date.now()
    })
  default:
    return state
  }
}
```


下面的selector在每一次REMOVE_OLD调用的时候,都会重新计算,因为Array.filter总是返回一个新对象.但是在大多数情况下,REMOVE_OLD action都不会改变todo列表,所以重新计算是不必要的.

```js
import { createSelector } from 'reselect'

const todosSelector = state => state.todos

export const visibleTodosSelector = createSelector(
  todosSelector,
  (todos) => {
    ...
  }
)
```


你可以通过state更新函数返回一个新对象来减少不必要的重计算操作,这个对象执行深度等值检测,只有深度不相同的时候才返回新对象.

```js
import { REMOVE_OLD } from '../constants/ActionTypes'
import isEqual from 'lodash.isEqual'

const initialState = [
  {
    text: 'Use Redux',
    completed: false,
    id: 0,
    timestamp: Date.now()
  }
]

export default function todos(state = initialState, action) {
  switch (action.type) {
  case REMOVE_OLD:
    const updatedState =  state.filter(todo => {
      return todo.timestamp + 30 * 24 * 60 * 60 * 1000 > Date.now()
    })
    return isEqual(updatedState, state) ? state : updatedState
  default:
    return state
  }
}
```


替代的方法是,在selector中使用深度检测方法替代默认的`equalityCheck`函数:

```js
import { createSelectorCreator, defaultMemoize } from 'reselect'
import isEqual from 'lodash.isEqual'

const todosSelector = state => state.todos

// create a "selector creator" that uses lodash.isEqual instead of ===
const createDeepEqualSelector = createSelectorCreator(
  defaultMemoize,
  isEqual
)

// use the new "selector creator" to create a selector
const mySelector = createDeepEqualSelector(
  todosSelector,
  (todos) => {
    ...
  }
)
```


检查`equalityCheck`函数的更替或者在state更新函数中做深度检测并不总是比重计算的花销小.如果每次重计算的花销总是比较小,可能的原因是Reselect没有通过`connect`函数传递`mapStateProps`单纯对象的原因.

### Q:没有Redux的情况下可以使用Reselect吗？

A:可以.Reselect没有其他任何的依赖包,因此尽管他设计的和Redux比较搭配,但是独立使用也是可以的.目前的版本在传统的Flux APP下使用是比较成功的.

>如果你使用`createSelector`创建的selectors,需要确保他的参数是immutable的.

>看[这里](#createselectorinputselectors--inputselectors-resultfunc)


### Q:怎么才能创建一个接收参数的selector.
A:Reselect没有支持创建接收参数的selectors,但是这里有一些实现类似函数功能的建议.

如果参数不是动态的,你可以使用工厂函数:

```js
const expensiveItemSelectorFactory = minValue => {
  return createSelector(
    shopItemsSelector,
    items => items.filter(item => item.value > minValue)
  )
}

const subtotalSelector = createSelector(
  expensiveItemSelectorFactory(200),
  items => items.reduce((acc, item) => acc + item.value, 0)
)
```
___

总的达成共识[看这里](https://github.com/reactjs/reselect/issues/38)和[超越 neclear-js](https://github.com/optimizely/nuclear-js/issues/14)是:如果一个selector需要动态的参数,那么参数应该是store中的state.如果你决定好了在应用中使用动态参数,像下面这样返回一个记忆函数是比较合适的:

```js
import { createSelector } from 'reselect'
import memoize from 'lodash.memoize'

const expensiveSelector = createSelector(
  state => state.items,
  items => memoize(
    minValue => items.filter(item => item.value > minValue)
  )
)

const expensiveFilter = expensiveSelector(state)

const slightlyExpensive = expensiveFilter(100)
const veryExpensive = expensiveFilter(1000000)
```
___

### Q：默认的记忆函数不太好,我能用个其他的吗？
A: 我认为这个记忆韩式工作的还可以,但是如果你需要一个其他的韩式也是可以的.
可以看看这个[例子](#customize-equalitycheck-for-defaultmemoize)

### Q:怎么才能测试一个selector?

A:对于一个给定的input,一个selector总是产出相同的结果.基于这个原因,做单元测试是非常简单的.

```js
const selector = createSelector(
  state => state.a,
  state => state.b,
  (a, b) => ({
    c: a * 2,
    d: b * 3
  })
)

test("selector unit test", () => {
  assert.deepEqual(selector({ a: 1, b: 2 }), { c: 2, d: 6 })
  assert.deepEqual(selector({ a: 2, b: 3 }), { c: 4, d: 9 })
})
```


在state更新函数调用的时候同时检测selector的记忆函数的功能也是非常有用的(例如 使用Redux的时候检查reducer).每一个selector都有一个`recomputations`方法返回重新计算的次数:
```js
suite('selector', () => {
  let state = { a: 1, b: 2 }

  const reducer = (state, action) => (
    {
      a: action(state.a),
      b: action(state.b)
    }
  )

  const selector = createSelector(
    state => state.a,
    state => state.b,
    (a, b) => ({
      c: a * 2,
      d: b * 3
    })
  )

  const plusOne = x => x + 1
  const id = x => x

  test("selector unit test", () => {
    state = reducer(state, plusOne)
    assert.deepEqual(selector(state), { c: 4, d: 9 })
    state = reducer(state, id)
    assert.deepEqual(selector(state), { c: 4, d: 9 })
    assert.equal(selector.recomputations(), 1)
    state = reducer(state, plusOne)
    assert.deepEqual(selector(state), { c: 6, d: 12 })
    assert.equal(selector.recomputations(), 2)
  })
})
```


另外,selectors保留了最后一个函数调用结果的引用,这个引用作为`.resultFunc`.如果你已经聚合了其他的selectors,这个函数引用可以帮助你测试每一个selector,不需要从state中解耦测试.

例如如果你的selectors集合像下面这样:

`selectors.js`
```js
export const firstSelector = createSelector( ... )
export const secondSelector = createSelector( ... )
export const thirdSelector = createSelector( ... )

export const myComposedSelector = createSelector(
  firstSelector,
  secondSelector,
  thirdSelector,
  (first, second, third) => first * second < third
)
```


单元测试就像下面这样:
`test/selectors.js`

```js
// tests for the first three selectors...
test("firstSelector unit test", () => { ... })
test("secondSelector unit test", () => { ... })
test("thirdSelector unit test", () => { ... })

// We have already tested the previous
// three selector outputs so we can just call `.resultFunc`
// with the values we want to test directly:
test("myComposedSelector unit test", () => {
  // here instead of calling selector()
  // we just call selector.resultFunc()
  assert(selector.resultFunc(1, 2, 3), true)
  assert(selector.resultFunc(2, 2, 1), false)
})
```


最后,每一个selector有一个`resetRecomputations`方法,重置recomputations方法为0,这个参数的意图是在面对复杂的selector的时候,需要很多独立的测试,你不需要管理复杂的手工计算,或者为每一个测试创建”傻瓜”selector.

### Q:Reselect怎么和Immutble.js一起使用?
A:`creatSelector`创建的Selectors应该可以和Immutable.js数据结构一起完美的工作.
如果你的selector正在重计算,并且你认为state没有发生变化,一定要确保知道哪一个Immutable.js更新方法,这个方法只要一更新**总是**返回新对象.哪一个方法只有**集合实际发生变化的时候**才返回新对象.

```js
import Immutable from 'immutable'

let myMap = Immutable.Map({
  a: 1,
  b: 2,
  c: 3
})

 // set, merge and others only return a new obj when update changes collection
let newMap = myMap.set('a', 1)
assert.equal(myMap, newMap)
newMap = myMap.merge({ 'a', 1 })
assert.equal(myMap, newMap)
// map, reduce, filter and others always return a new obj
newMap = myMap.map(a => a * 1)
assert.notEqual(myMap, newMap)
```


如果一个操作导致的selector更新总是返回一个新对象,可能会发生不必要的重计算.[看这里](#q-why-is-my-selector-recomputing-when-the-input-state-stays-the-same).这是一个关于pros的讨论,使用深全等于来检测例如`immutable.js`来减少不必要的重计算过程.

### Q:可以在多个组件之间共享selector吗？
A: 使用`createSelector`创建的Selector的缓存的大小只有1.这个设定使得多个组件的实例之间的参数不同,跨组件共享selector变得不合适.这里也有几种办法来解决这个问题:

* 使用工程函数方法,为每一个组件实例创建一个新的selector.这里有一个内建的工厂方法,React Redux v4.3或者更高版本可以使用. [看这里](#sharing-selectors-with-props-across-multiple-components)
* 创建一个缓存尺寸大于1的定制selector.


### Q:有TypeScript的类型吗？
A: 是的！他们包含在`package.json`里.可以很好的工作.

### Q：怎么构建一个[柯里化](https://github.com/hemanth/functional-programming-jargon#currying)selector?
A：尝试一些这里[助手函数](https://github.com/reactjs/reselect/issues/159#issuecomment-238724788),由[MattSPalmer](https://github.com/MattSPalmer)提供

## 有关的项目

### [reselect-map](https://github.com/HeyImAlex/reselect-map)

因为Reselect不可能保证缓存你所有的需求,在做**非常昂贵的计算**的时候,这个方法比较有用.查看一下reselect-maps readme

**reselect-map的优化措施仅仅使用在一些小的案例中,如果你不确定是不是需要他,就不要使用它**.

## License

MIT

[build-badge]: https://img.shields.io/travis/reactjs/reselect/master.svg?style=flat-square
[build]: https://travis-ci.org/reactjs/reselect

[npm-badge]: https://img.shields.io/npm/v/reselect.svg?style=flat-square
[npm]: https://www.npmjs.org/package/reselect

[coveralls-badge]: https://img.shields.io/coveralls/reactjs/reselect/master.svg?style=flat-square
[coveralls]: https://coveralls.io/github/reactjs/reselect
















