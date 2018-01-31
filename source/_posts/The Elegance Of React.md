---
title: 翻译|The Elegance Of React
date: 2018-01-30 08:17:07
categories: 翻译
tags: [React, hoc, javascript, Redux]
---

[原文参见]()
## 内容 ##

- [General](#general)
- [Compose组件](#Compose组件)
- [Compose和组件的限制](#Compose和组件的限制)
- [Reducing组件](#Reducing组件)
- [Adding Redux](#AddingRedux)
### General ###
  
本篇文章着眼是如何编写优雅的 React 代码.我们会结合 React和`Ramda`,以函数式风格来编写应用.所有的概念对于 lodash/fp其他的函数式编程库也是适合的.关键在于你使用哪种库.

本文示例使用[`*eslint-config-cleanjs*`](https://github.com/bodil/eslint-config-cleanjs),来强化函数式风格,其中包括*no-this*和*no-classes*规则.这些函数式规则可以让我在开始下面的示例时采用更规范.如果你对配置感兴趣,可以到 github 仓库看看具体的规则设置
### Compose组件 ###
让我们从更为容易接受的方法开始吧!看看下面的代码:

```js
const comp=(f,g)=>x=>f(g(x))
```

如果是组件,实现代码是这样的:

```js
const TodoList=(List,mapItems)=>s=>List(mapItems(s))
```

这么做就有意义了,可以让我们通过`compose`小的组件来构建更大的组件.

```js
const List = c => <ul>{c}</ul>
const Item = todo => <li key={todo.id}>{todo.name}</li>
const TodoList = compose(List, map(Item))
const result = TodoList([{id: 1, name: 'foo'}])
```

**TodoList**是一个函数等待应用的 state并且根据对应的 state 返回新的组件.代码非常简洁,有意义.我们遍历了一些 todo 的条目,并由此创建Item列表.之后结果借助 props 传递给 TodoList,并且在组件内部渲染.

牢记:

```js
const App = state => List(map(Item, state)))
```

组件渲染其他子组件的想法工作良好,编写的大多数组件都不依赖*JSX*,只依赖传递进入的 state.所以这个方法只对小的子组件起作用.

下面是使用 Ramda map,compose,prop 方法的实例代码:

```js
import React from 'react'
import { render } from 'react-dom'
import { compose, map, prop } from 'ramda'
const List = items => <ul>{items}</ul>
const Item = todo => <li key={todo.id}>{todo.text}</li>
const getTodos = prop('todos')
const TodoList = compose(List, map(Item), getTodos)
const props = {todos: [{id: 1, text: 'foo'}, {id: 2, text: 'bar'}]}
render(<TodoList {...props} />, document.getElementById('root'))
```

### Compose和组件的限制 ###
现在我们已经可以compose 组件并渲染出 Todo list. 接下来看看更为常见的方法,也就是 props 可以自顶向下传递.这些 props可以是任何内容,包括回调函数,其他组件以及数组和对象.下面的代码和 Todo List 的代码相同,只是包含额外的 Header 组件

```js
const Header = title => <h1>A Todo List: {title}</h1>
const List = items => <ul>{items}</ul>
const Item = todo => <li key={todo.id}>{todo.text}</li>
```

没有什么特别的,但是看看回头看看之前的实现方法,明确的表明,在 List 中包含一个 header 是不可能的.之前的compse:

```js
const TodoList = compose(List, map(Item), getTodos)
```

实际编程中我们需要能够 compose Header 和 List 的方法, Header放在哪里合适? 我们向 TodoList 函数传递了应用的state,接着经过筛选,然后遍历筛选过的 todos创建Items 的数组,然后传递给 List.Header组件如何才能从 state 中获取到标题信息?需要更好的办法.

说的更明白一点:

```js
const TodoHeader = mapStateToProps => Header(mapStateProps)
```

**订正** 这里哟一个更好的实现方法(感谢[Thai Pangsakulyanont](https://medium.com/@dtinth))

```js
const TodoHeader = todoState =>
  Header(getTitleFromTodoState(todoState))
```

我们希望是传递应用的 state接着使所有的组件各取所需的 properties.为了让思路更清晰,调用 `mapStateToProps` 函数

```js
const mapStateToProps = curry((f, g) => compose(g, f))
```

`mapStateToProps`等待一个函数还有组件,之后首先针对提供的 state 应用函数,之后结果传递给组件.需要注意这一点,我们柯理化了函数,仅仅是想把筛选 state的定义和实际的组件分离开. 在这个问题上, Ramda的绝大多数函数都是自动柯理化的.

下面代码是如何在 Header组价中应用`mapStateToProps`.

```js
const TodoHeader = mapStateToProps(s => s.title, Header)
const result = TodoHeader(state)
```


这看起来和 react-redux 的*connect()*函数和类似了.我们使用`mapStateToProps`把state的特定部分转化为 props. 现在 Header 和之前的 List组价可以分别获取各自的 state信息了.

```js
const TodoList = mapStateToProps(getTodos, compose(List, map(Item))
const result = TodoList(state)
```

显然,`mapStateToProps`只解决了一部分问题,我们仍然需要 compose TodoList 和 Header来创建整个应用的能力.

使用 compose 不能解决这个问题.所以来实现我们自己的工具函数`combine`.需要两个组件并返回一个新的组件.

```js
const combine = curry((c, o) => x => (<div>{c(x)} {o(x)}</div>))
```

使用 `combine`函数可以 compose Header 和 List创建新的函数.

```js
const TodoHeader = mapStateToProps(s => s.title, Header)
const TodoList = mapStateToProps(getTodos, compose(List, map(Item)))
const App = combine(TodoHeader, TodoList)
render(<App {...state} />, document.getElementById('root'))
```

现在 compose 两个分别获取特定state 的方式已经有了.接着更进一步看看怎么 compose 更多的组件

### Reducing组件###

如果需要在应用中添加一个显示当前年份的 Footer 组件.怎么才能做到这一点? 首先想到的办法是:

```js
const App = combine(TodoHeader, combine(TodoList, TodoFooter))
```

 首先Combine TodoList 和 TodoFooter,接着再 combine 之前的结果和 TodoHeader.这么做是可行的,但是如果组件再多一点,代码就不太好懂了.
 
可以考虑像下面一样操作:

```js
// array of components 
const comps = [TodoHeader, TodoList, TodoFooter]
const App = comps => 
  reduce((acc, x) => combine(acc, x), init, comps)
```

有了想法,看看实际的实现

```js
const combineComponents = (...args) => {
  const [first, ...rest] = args
  return reduce((acc, c) => combine(acc, c), first, rest)
}
```

参考 redux中的`combineReducers`,我们把自己的 reducer 称为`combineComponents`, `combineComponents` 接收一组组件,并 Reduce为等待组件 state 的单个函数.

```js
const App = combineComponents(TodoHeader, TodoList, TodoFooter)
render(<App {...state} />, document.getElementById('root'))
```

有了`mapStateToProps`, `combine`, `combineComponents` 的协助,我们现在就可以 compose 组件了.考虑到 mapStateToProps, 我们可以最一下最后的提炼.看看刚开始的实现方法

```js
const mapStateToProps = curry((f, g) => compose(g, f))
```

实际上,我们完全没有必要自己实现它.Ramda或者 lodash/fp 已经提供了一个函数:`pipe`. `pipe`函数从左至右运行所有的函数.看看下面的例子

```js
const add = x => x + 1
const multiplyByFour = x => x * 4
// pipe === flip(compose)
const rCompose = flip(compose)
rCompose(add, multiplyByFour)(1) === compose(multiplyByFour, add)(1)
rCompose(add, multiplyByFour)(1) === pipe(add, multiplyByFour)(1)
```

所以`pipe`和 `compose`很像,只不过参数方向是相反的. 我们使用了 Ramda的`flip`函数,这个函数在本实例中 翻转两个参数的方向.意味着,我们现在可以重构 `mapStatToProps`为:

```js
const mapStateToProps = pipe
```

或者直接使用`pipe`函数,让 Ramda 担起全责.这么做以后,留给我们两个函数`combine`和`combineRedcers`需要处理.甚至combine 函数都可以隐藏起来,但是为了推理清晰一点,还是保留吧!

完整的代码如下:

```js
import React from 'react'
import { render } from 'react-dom'
import { compose, map, prop, curry, reduce, pipe } from 'ramda'

const combine = curry((c, o) => x => (<div>{c(x)} {o(x)}</div>))
const combineComponents = (...args) => {
  const [first, ...rest] = args
  return reduce((acc, c) => combine(acc, c), first, rest)
}

const state = {
  year: '2016',
  title: 'Random stuff',
  todos: [{id:1, text: 'foo'}, { id:2, text: 'bar'}]
}

const getTodos = prop('todos')

const Header = title => <h1>A Todo List: {title}</h1>
const List = items => <ul>{items}</ul>
const Item = todo => <li key={todo.id}>{todo.text}</li>
const Footer = text => <div>{text}</div>

const TodoHeader = pipe(s => s.title, Header)
const TodoList = pipe(getTodos, compose(List, map(Item)))
const TodoFooter = pipe(s => s.year, Footer)

const App = combineComponents(TodoHeader, TodoList, TodoFooter)
const result = render(<App {...state} />, document.getElementById('root'))
```

### Adding Redux###
 Reduce一切组件? 下面的伪代码,帮助我们创建要达成目标的心里模型
 
```js
const App=(state,action)=>TodoList
```

上面的代码看起来有点像典型的 Redux reducers,不同点是我们在这里返回的是一个 React 组件,并不是经过计算的state.如果要借助 Readux 来完成这个目标? 试试看

我们仍然来构建一个 TodoList,并且保持清晰明了,会使用译注 redux todomvc 的actions 和 todo reducer.

```js

// constants
const ADD_TODO = 'ADD_TODO'
const DELETE_TODO = 'DELETE_TODO'
// actions
const addTodo = text => ({type: ADD_TODO, text })
const deleteTodo = id => ({ type: DELETE_TODO, id })
// reducers
const todos = createReducer([], {
  [ADD_TODO]: (state, action) => [
    { id: getNextId(state), completed: false, text: action.text },
    ...state
  ],
  [DELETE_TODO]:(state, action) =>
    reject(propEq('id', action.id), state),
})
```

部分原始的reducer 代码通过使用 Ramda的 `reject`和
`propEq`重构来过滤已经删除掉的 todo条目.万一你想知道`reject`是什么函数,`reject`是 filter的补集.我们可以编写一组助手函数:

```js
// redux utils
// alternative is to use defaultTo instead propOr
const createReducer = (init, handlers) =>
  (state = init, action) =>
    propOr(identity, prop('type', action), handlers)(state, action)
const addOne = add(1)
const getAllIds = pluck('id')
const getMax = reduce(max, 0)
const getNextId = compose(addOne, getMax, getAllIds)
```

`getNextId`是用于获取下一个 id 的函数,在添加新的条目是,需要用到它.`createReducer`已经在在 Redux的顶层输出中出现了,但是这里的是使用 Ramda重写的版本.
现在我们已经有了 reducers和 Action.现在需要适配他们和我们的组件以便于处理添加和删除组件.为了保持简单,我们用一个 add 按钮来代替输入文本添加 todo项文本的操作.

```js
const Add = onSave => (
  <div>
    <button onClick={() => onSave('foobar')}>Add</button>
  </div>
)
```

最后还需要一个删除按钮.在 Item组件中添加一个删除按钮就足够了.

```js
const Item = ({todo, removeTodo }) => (
  <li key={todo.id}>
    {todo.text} <button onClick={removeTodo}>Remove</button>
  </li>
)
```

需要的部分都已经就绪了.这里仍然有一些部分需要澄清:`removeTodo`应该 dispatch `deleteTodo` action. 另一个需要考虑的方面是,我们需要一个方法定义必须要提供的 dispatcher. 现在我们还仅仅是映射 state 到 props.

来添加一个 `getRender`函数,等待输入应用入口节点,返回一个等待 React 组件的函数.

```js
const getRender = node => app => ReactDOM.render(app, node)
const render = getRender(document.getElementById('root'))
render(<App {...state} />)
```

接下来编写一个 bindActionCreator.

```js
// define a bindActionCreator
const bindAction = curry((dispatch, actionCreator) =>
  compose(dispatch, actionCreator))
const bindActionCreator = bindAction(store.dispatch)
```

接着隐藏掉 `dispatch`方法,同时传递`bindActionCreator` 和 state 到应用,并且订阅到 Redux 的 store,当代触发渲染. 要声明一下, Redux 已经有可以直接使用的 bindActionCreators 函数.

```js
const run = store.subscribe(() =>
  render(
    <App {...store.getState()} dispatch={bindActionCreator} />
  )
)
```

最后的一些收尾工作是适配 Item和 TodoList 组件, Items 期待 todo条目还有 `onDelete`函数

```js
const Item = ({todo, onDelete}) => (
  <li key={todo.id}>
    {todo.text}
    <button onClick={() => onDelete(todo.id)}>Remove</button>
  </li>
)
```

因为现在 Item组件也需要`onDelete`函数,我们需要适配`map to props`函数.我们已经获取了 dispatch,所以返回一个todo items 的数组了,需要范湖一个包含 todo数组和`onDelete`函数的对象.

```js
// for clearer understanding extracted mapItems
const mapItems = ({todos, onDelete}) =>
  map(todo => Item({todo, onDelete}), todos)
const TodoList = pipe(props =>
    ({todos: props.todos, onDelete: props.dispatch(deleteTodo)}),
  compose(List, mapItems)
)
``` 

下面就是最终的代码,也可以查看[`实例代码`](https://plnkr.co/edit/adPsyH9r6OIjsu9fDhgz?p=preview)

```js
import React from 'react'
import ReactDOM from 'react-dom'
import { createStore, combineReducers } from 'redux'
import * as R from 'ramda'

// composition helper
const combine = R.curry((c, o) => x => (<div>{c(x)} {o(x)}</div>))
const combineComponents = (...args) => {
  const [first, ...rest] = args
  return R.reduce((acc, c) => combine(acc, c), first, rest)
}

// helpers
const targetValue = e => e.target.value
const getTodos = R.prop('todos')

// redux utils
const createReducer = (init, handlers) =>
  (state = init, action) =>
    R.propOr(R.identity, R.prop('type', action), handlers)(state, action)

const addOne = R.add(1)
const getAllIds = R.pluck('id')
const getMax = R.reduce(R.max, 0)
const getNextId = R.compose(addOne, getMax, getAllIds)

// constants
const ADD_TODO = 'ADD_TODO'
const DELETE_TODO = 'DELETE_TODO'

// actions
const addTodo = text => ({type: ADD_TODO, text })
const deleteTodo = id => ({ type: DELETE_TODO, id })

// reducers
const todos = createReducer([], {
  [ADD_TODO]: (state, action) => [
      { id: getNextId(state), completed: false, text: action.text },
      ...state
    ],
  [DELETE_TODO]:(state, action) => R.reject(R.propEq('id', action.id), state),
})

const year = createReducer('', {})
const title = createReducer('', {})

// combine reducer and create store
const reducers = combineReducers({todos, year, title})

const initialState = {
  year: '2016',
  title: 'Random stuff',
  todos: [{id:1, text: 'foo'}, { id:2, text: 'bar'}]
}

const store = createStore(reducers, initialState)

// components
const Header = title => <h1>A Todo List: {title}</h1>
const Add = ({onSave}) => (
  <div>
    <button onClick={() => onSave('foobar')}>Add</button>
  </div>
)
const List = items => <ul>{items}</ul>
const Item = ({todo, onDelete}) => (
  <li key={todo.id}>
    {todo.text} <button onClick={() => onDelete(todo.id)}>Remove</button>
  </li>
)
const Footer = text => <div>{text}</div>

// define a bindActionCreator
const bindAction = R.curry((dispatch, actionCreator) =>
  R.compose(dispatch, actionCreator))
const bindActionCreator = bindAction(store.dispatch)

// map state to props
const TodoHeader = R.pipe(props => props.title, Header)
const TodoAdd = R.pipe(props => ({onSave: props.dispatch(addTodo)}), Add)
const mapItems = ({todos, onDelete}) =>
  R.map(todo => Item({todo, onDelete}), todos)
const TodoList = R.pipe(props =>
  ({todos: props.todos, onDelete: props.dispatch(deleteTodo)}),
  R.compose(List, mapItems)
)
const TodoFooter = R.pipe(props => props.year, Footer)

// combine all components
const App = combineComponents(TodoHeader, TodoAdd, TodoList, TodoFooter)

// we could also have used curry...
const getRender = node => app => ReactDOM.render(app, node)
const render = getRender(document.getElementById('root'))

const run = store.subscribe(() =>
  render(<App {...store.getState()} dispatch={bindActionCreator} />))

// start
const init = store.dispatch({type: '@@INIT'})
```

### Outro ###
 
这篇文章的目的是介绍如何联合 Ramda,React和 Redux来编写更加优雅的代码.
例子只是用来说明如何在React 或者 Redux 中使用 Ramda.在实际的编程中,你可以在应用的某些部分借助Ramda或者 lodash/fp 来编写优雅的代码.

例如可以重构`mapDispatchToProps`函数,根据定义好的 `propTypes`自动映射 state到应用的props,代替手动输入.

```js
const getPropTypes = prop('propTypes')
const pickKeys = compose(pick, keys)
const mapStateToProps = compose(pickKeys, getPropTypes)
// map state to defined propTypes.
export default connect(mapStateToProps(App))(App)
```

也可以使用 Ramda 的 `pick`函数替代 mapDispatchToProps 函数.

```js
export default connect(pick(['todos']))(App)
```

[`If you have any questions or feedback don’t hesitate to leave feedback @ twitter.`](https://twitter.com/sharifsbeat)

这篇文章受到[`Brian Lonsdorf`](https://medium.com/@drboolean) 在 React Rally上演讲的启发.



