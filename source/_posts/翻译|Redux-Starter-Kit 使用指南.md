---
title: 翻译|Redux-Starter-Kit 使用指南
date: 2019-04-25 14:55
categories: 技术备忘
tags: [React,Redux]
---


>[`‌原文在这里`](https://redux-starter-kit.js.org/usage/usage-guide),
>这是Redux官方的充电包工具集,可以使Redux的用法简单一点. 本文是文档中的用户指南的翻译版本
[^译注:这里的包装只是简化了操作,概念性问题的难度并没有降低,因此在没有理解Redux核心概念之前,Redux的文档任然是学习的敲门砖]

## 前言
Redux核心库刻意安排为没有任何偏向性.因此可以让使用者自己来处理每个问题,例如包含了state的State的配置,以及怎么构建reducers.
在某些使用案例中,是很好的,因为这么样做给了你很大的灵活性,但是用户并不总是需要灵活性.有时候,我们需要的只是尽肯能简单的开始工作,只需要有开箱即用的默认配置就可以.又或者是,你正在编写一个大型的应用,发现自己写了太多类似的代码,你非常希望能山减掉大量的手写代码.

正如在[`快速入门`](https://redux-starter-kit.js.org/introduction/quick-start)中讲到的一样,Redux Starter Kit的目标是协助简化Redux的常见使用用例.它并没有像你想象的那样成为一个完整的解决方案,而是使得一些Redux相关代码的编写变简单(或者在某些情况下,彻彻底底的减少手写代码的量).

Redux Starter Kit 导出了几个可供使用的独立函数,在其他的包中添加依赖就可以和Redux一起工作.这可以让你决定,到底是在全新的项目还是已经进行的项目中使用Kit.

接下来看看一些Redux Starter Kit的用法,这些用法可以让你的Redux代码更漂亮.

## Store的配置
每个Redux App需要配置并创建一个Store,通常情况下包含以下几个步骤:
- 导入或者创建顶层reducer函数(root reducer function)
- 配置中间件(middleware),例如包含至少一个有关异步操作逻辑的中间件
- 配置[`Redux DevTools 扩展`](https://github.com/zalmoxisus/redux-devtools-extension)
- 尽你所能的配置一些专门用于开发环境或者产品环境的切换逻辑
###   Store的手工配置
 下面的代码是 Redux文档 [`‌配置Store`](https://redux.js.org/recipes/configuring-your-store)中的典型代码
 
 ```javascript
 import { applyMiddleware, compose, createStore } from 'redux'
import { composeWithDevTools } from 'redux-devtools-extension'
import thunkMiddleware from 'redux-thunk'

import monitorReducersEnhancer from './enhancers/monitorReducers'
import loggerMiddleware from './middleware/logger'
import rootReducer from './reducers'

export default function configureStore(preloadedState) {
  const middlewares = [loggerMiddleware, thunkMiddleware]
  const middlewareEnhancer = applyMiddleware(...middlewares)

  const enhancers = [middlewareEnhancer, monitorReducersEnhancer]
  const composedEnhancers = composeWithDevTools(...enhancers)

  const store = createStore(rootReducer, preloadedState, composedEnhancers)

  if (process.env.NODE_ENV !== 'production' && module.hot) {
    module.hot.accept('./reducers', () => store.replaceReducer(rootReducer))
  }

  return store
}
 ```
 
实例代码的可读性还可以,但是流程不太直接明了:

- 基础的Redux `createStore`函数接收几个固定位置的参数:(`rootReducer,preloadedState,enhancer`).有时候很容易忘记其中的参数.
- 中间件(middleware)和增强件(enhancer)的设定过程令人感到困惑,尤其是你准备添加多个配置的时候.
- Redux DevTools 扩展文旦初始建议你使用一些手写文档检查全局作用域中可用的扩展.很多用户只是简单的拷贝粘贴这些代码块,这使得配置代码很难理解.


### 使用`configureStore`函数简化Store的配置

 `configureStore`在一下几个方面对我们有帮助:
 - 有一个"name"参数的可选对象,很容易读懂.
 - 允许你提供中间件和增强件的数组,用于在store中添加这些组件,并自动调用`applyMiddleware`和`compose`函数.
 - 自动开启Redux DevTools扩展

  此外,`confitureStore`默认添加了一些有特定用途的中间件:
  - `redux-thunk` 是在组件外执行同步和异步逻辑的常用中间件
  - 在开发环境,用于检查常见state mutate操作或者使用非序列化错误的中间件.

  这么做意味着,store的配置代码本身更短,更容易阅读.
  
  最简答的用法是只要把顶层reducer函数作为`reducer` 形参传递就可以了.
  
  ```javascript
import { configureStore } from 'redux-starter-kit'
import rootReducer from './reducers'

const store = configureStore({
  reducer: rootReducer
})

export default store
  ```

也可以传递分片(slice)的reducer,`configureStore`会自动调用`combineReducers`:

```javascript
import usersReducer from './usersReducer'
import postsReducer from './postsReducer'

const store = configureStore({
  reducer: {
    users: usersReducer,
    posts: postsReducer
  }
})
```

注意,这个用法只对第一级的reducer有用.如果你想嵌套reducer,需要自己调用`combineReducers`来完成更低一级的嵌套.

如果你想定制store的配置,可以传递额外的选项.这里是热加载的实例:

```javascript
import { configureStore, getDefaultMiddleware } from 'redux-starter-kit'

import monitorReducersEnhancer from './enhancers/monitorReducers'
import loggerMiddleware from './middleware/logger'
import rootReducer from './reducers'

export default function configureAppStore(preloadedState) {
  const store = configureStore({
    reducer: rootReducer,
    middleware: [loggerMiddleware, ...getDefaultMiddleware()],
    preloadedState,
    enhancers: [monitorReducersEnhancer]
  })

  if (process.env.NODE_ENV !== 'production' && module.hot) {
    module.hot.accept('./reducers', () => store.replaceReducer(rootReducer))
  }

  return store
}
```

如果你提供了`middleware`参数, `confitureStore`就只使用你提供的中间件. 如果你想在默认中间件基础上添加定制的中间件,可以调用`getDefaultMiddleware`,把你自己的中间件数组包含进去.

## 编写Reducers
   
Reducers是Redux中最重要的概念,一个典型的reducer函数需要具备的功能是:
- 查找action对象的`type` 字段,来决定如何响应action
- 通过拷贝state中需要修改的部分,只修改这些部分,从而不可突变的更新Redux的state.

当你在reducer中使用需要的条件逻辑是,最常见的方法是`switch`声明,因为针对单个字段执行最直接的操作.然而很多人不喜欢switch声明.Redux文档展示了基于action type类型的映射的用法,但是需要你自己配置.

另一个常见的痛点是编写reducers时,不要有不可突变的更新state.Javascript是可突变的语言.[`手动更新嵌套的数据非常棘手`](https://redux.js.org/recipes/structuring-reducers/immutable-update-patterns),很容易出错.

### 使用`createReducer`函数简化Reducer的操作

因为"查表"(映射)方法很流行,Redux Starter Kit 包含了一个类似Redux 文档中`createReducer`的函数.然而我们的`createReducer`工具有一些魔法,是的Reducer的操作更好,在内部它使用['Immer'](https://github.com/mweststrate/Immer)库,Immer库可以让你编写假的"突变"代码,实际上进行了不可突变更新.这么做有效的避免了偶然的突变操作.

总体上,任何使用`switch`声明的Reducx Reducer都可以直接转化使用`createReducer`. switch中每个`case`都变成传递给`createReducer`对象的一个键. 不可突变更新逻辑,例如对象展开操作,拷贝数组都可以直接转换为"可突变"操作 . 保持原来的不可突变操作也可以, 只需返回更新的拷贝就行. 

这里有一些可以使用`createReducer`的实例. 我们从经典的"todo list" reducer开始,使用的是switch声明和不可突变更新

```javascript
function todosReducer(state = [], action) {
    switch(action.type) {
        case "ADD_TODO": {
            return state.concat(action.payload);
        }
        case "TOGGLE_TODO": {
            const {index} = action.payload;
            return state.map( (todo, i) => {
                if(i !== index) return todo;

                return {
                    ...todo,
                    completed : !todo.completed
                };
            });
        } ,
        "REMOVE_TODO" : (state, action) => {
            return state.filter( (todo, i) => i !== action.payload.index)
        }
        default : return state;
    }
}
```

注意:我们声明调用了`state.concat()`,返回包含todo新条目的经过拷贝的数组,`state.map()` 返回toggle分支的拷贝数组,这里使用对象展开操作符对要更新的todo项进行了复制.

通过使用`createReducer`,我们可以考虑简化实例:

```javascript
const todosReducer = createReducer([], {
    "ADD_TODO" : (state, action) => {
        // "mutate" the array by calling push()
        state.push(action.payload);
    },
    "TOGGLE_TODO" : (state, action) => {
        const todo = state[action.payload.index];
        // "mutate" the object by overwriting a field
        todo.completed = !todo.completed;
    },
    "REMOVE_TODO" : (state, action) => {
        // Can still return an immutably-updated value if we want to
        return state.filter( (todo, i) => i !== action.payload.index)
    }
})
```

"突变"state的能力在试图更新深度嵌套的state时特别有用.复杂而令人痛苦的代码如下:

```javascript
case "UPDATE_VALUE":
  return {
    ...state,
    first: {
      ...state.first,
      second: {
        ...state.first.second,
        [action.someId]: {
          ...state.first.second[action.someId],
          fourth: action.someValue
        }
      }
    }
  }
```

可以简化为下面的代码:

```javascript
updateValue(state, action) {
    const {someId, someValue} = action.payload;
    state.first.second[someId] = someValue;
}
```

看上去好多了
[^译注:这里看上去是可突变操作,实际底层使用的Immer在操作之前已经进行了拷贝操作,不会在原始内存地址做修改].

### 以对象的形式定义函数

在现代Javascript中,有几个固定好的方法可以在对象中定义键和函数(并不是特定针对Redux),所以你可以混合匹配不同的键定义和函数定义. 例如下面对象中所有的函数定义方法都是合规的.

```javascript
const keyName = "ADD_TODO4";

const reducerObject = {
    // Explicit quotes for the key name, arrow function for the reducer
    "ADD_TODO1" : (state, action) => { }

    // Bare key with no quotes, function keyword
    ADD_TODO2 : function(state, action){  }

    // Object literal function shorthand
    //对象字面量函数简写方式
    ADD_TODO3(state, action) { }

    // Computed property
    [keyName] : (state, action) => { }
}
```

使用`对象字面量函数简写方式` 可能是最简短的代码,但是你可以使用以上任何一种方式.

### 使用`createReducer`要考虑的因素

 Redux Starter Kit的`createReducer`函数可以发挥很大的作用,但是也要留心:
  - "突变"的代码只能在`createReducer`函数内使用
  - Immer不允许混合突变(译注:这里指的是真正的JS突变操作)操作,又返回新的state.

 查看[`createReducer API  参考`](https://redux-starter-kit.js.org/api/createReducer) ,了解具体的详情.
 
 ## 编写 Action Creators
 
 Redux鼓励使用者[`编写action creator 函数`](https://blog.isquaredsoftware.com/2016/10/idiomatic-redux-why-use-action-creators/),action creator函数封装了创建Action 对象的流程. 但是标准的Redux用法中不是必须的.
 
 绝大多数的action creator都非常简单.它们接受一些参数,返回一个拥有特定`type`字段和传入参数的 action对象.这些参数通常放在`payload`字段下,  action队形是`‌Flux标准action`的传统定义,目的是组织action对象的内容. 一个典型action creator的结构如下:
 
 ```javascript
 function addTodo(text) {
  return {
    type: 'ADD_TODO',
    payload: { text }
  }
}
 ```
 
 
 ### 使用`createAction`函数定义Action Creators
 
 手动编写action creators很乏味.Redux Starter Kit提供了一个函数 `createAction`,用于简化给定了action type的action对象的创建过程,传入的参数安置在`payload`字段中:
 
 ```javascript
 const addTodo = createAction('ADD_TODO')
addTodo({ text: 'Buy milk' })
// {type : "ADD_TODO", payload : {text : "Buy milk"}})
```


目前,`creatAction`不允许你定制`payload`字段. 必须要把`payload`作为整个参数来传递.`payload` 可以是单个的值,或者一个有大量数据的对象(我们最终会为`‌createAction`添加一个用于定制payload的回调函数,或者是可以添加其他类似`meta`一样的字段).

### 把Action Creatros 作为Action Type

Redux的reducers函数需要查找特定的action types来决定该如何更新state.通常情况下, 定义action type 字符串和定义action creator函数式分开的. Redux Starter Kit的`createAction`函数使用了一套技巧让两个定义更容易了.

首先,`createAction` 在它生成的action creators上 重写了`toString()`方法. 意思是,action creators自身也可以作为"action type"来引用,例如可以作为`creareReducer`的键.

第二点,action type也可以定义为action creator的一个`type` 字段.

```javascript
const actionCreator = createAction("SOME_ACTION_TYPE");

console.log(actionCreator.toString())
// "SOME_ACTION_TYPE"

console.log(actionCreator.type);
// "SOME_ACTION_TYPE"

const reducer = createReducer({}, {
    // actionCreator.toString() will automatically be called here
    [actionCreator] : (state, action) => {}

    // Or, you can reference the .type field:
    [actionCreator.type] : (state, action) => { }
});
```

这意味着,你不需要编写或使用独立的action type变量,或或者重复action type的名字和值,例如`const SOME_ACTION_TYPE = "SOME_ACTION_TYPE"` 就不需要了. 

不幸的是,隐式转换为字符串对于switch声明不起作用.如果你在一个switch 声明中使用了这些action creator,需要你自己调用`actionCreator.toString()`

```javascript
const actionCreator = createAction('SOME_ACTION_TYPE')

const reducer = (state = {}, action) => {
  switch (action.type) {
    // ERROR: 这里会出错, 在switch中,actionCreator不会自动获取字符串
    case actionCreator: {
      break
    }
    // CORRECT: this will work as expected
    case actionCreator.toString(): {
      break
    }
    // CORRECT: this will also work right
    case actionCreator.type: {
      break
    }
  }
}
```

如果你同时使用了Redux Starter Kit和TypeScript,要留心, 在action creator 用于对象的键时,TypeScript编译器不会接受 `toString()`的隐式转换.这种情况下,你需要手动转换(actionCreator as string),或者使用`.type`字段作为键.

## 创建 分片的State,
Redux 的state通常都以"切片"的形式组织,由reducers定义的切片 state传递给`combineReducers`.

```javascript
import { combineReducers } from 'redux'
import usersReducer from './usersReducer'
import postsReducer from './postsReducer'

const rootReducer = combineReducers({
  users: usersReducer,
  posts: postsReducer
})
```

在这个例子中,`users`和`posts`都被认为是"切片(slices)".也都是reducers:

-  "拥有"state中的一块, 包括初始值
-  定义了state更新的方法
-  定义了会引起state更新的特定Action

 常规的方法是在自己独立的文件中定义切片reducer函数,action creators在第二个文件中.因为两个文件都需要引用同样的action types, 又会在第三个文件中定义,并在前两个文件中导入:
 
 ```javascript
 // postsConstants.js
const CREATE_POST = 'CREATE_POST'
const UPDATE_POST = 'UPDATE_POST'
const DELETE_POST = 'DELETE_POST'

// postsActions.js
import { CREATE_POST, UPDATE_POST, DELETE_POST } from './postConstants'

export function addPost(id, title) {
  return {
    type: CREATE_POST,
    payload: { id, title }
  }
}

// postsReducer.js
import { CREATE_POST, UPDATE_POST, DELETE_POST } from './postConstants'

const initialState = []

export default function postsReducer(state = initialState, action) {
  switch (action.type) {
    case CREATE_POST: {
      // omit implementation
    }
    default:
      return state
  }
}
 ```
 
 这唯一必不可少的部分只有reducer自己,想想其他部分:
 
 -  我们可以在两个地方编写action type 作为行内字符串.
 -  action creators很好,但是对于使用Redux不是必须的,一个组件可以直接跳过由`connect`提供的`mapDispatch`参数,转而直接使用`this.porps.dispatch({type:'CREATE_POST',payload:{id:123,title:"Hello World"}})`
 -  唯一要这么写的原因是因为这是常规的做法.

   [`"‌鸭式"文件结构`](https://github.com/erikras/ducks-modular-redux) 建议把所有的Redux相关逻辑放到一个单一文件中,像这样:
   
   ```javascript
   // postsDuck.js
const CREATE_POST = 'CREATE_POST'
const UPDATE_POST = 'UPDATE_POST'
const DELETE_POST = 'DELETE_POST'

export function addPost(id, title) {
  return {
    type: CREATE_POST,
    payload: { id, title }
  }
}

const initialState = []

export default function postsReducer(state = initialState, action) {
  switch (action.type) {
    case CREATE_POST: {
      // Omit actual code
      break
    }
    default:
      return state
  }
}
```

这样做简化了很多事,因为我们不需要多个文件,所以可以移除掉冗余的action type 常量的导入.但是,我们仍然要手动编写action types和action creators.

### 使用`createSlice`简化Slices(切片)的创建

为了简化这个过程,Redux Starter Kit 包含了一个`createSlice`函数, 可以根据你提供的reducer函数的名字自动生成action type和action creators.

这里是pops的实例代码:

```javascript
const postsSlice = createSlice({
  initialState: [],
  reducers: {
    createPost(state, action) {},
    updatePost(state, action) {},
    deletePost(state, action) {}
  }
})

console.log(postsSlice)
/*
{
    actions : {
        createPost,
        updatePost,
        deletePost,
    },
    reducer
}
*/

const { createPost } = postsSlice.actions

console.log(createPost({ id: 123, title: 'Hello World' }))
// {type : "createPost", payload : {id : 123, title : "Hello World"}}
```

`createSlice`查找所有在`reducers`字段中定义的函数,以及每一个"case reducer"函数,用reducer的名字生成同名的action creator和action type.所以, `createPost` reducer 将会返回 一个`createPost`类型,和`createPost()` action creator. 

也可以选择性定义一个`slice`参数用于action type的前缀:

```javascript
const postsSlice = createSlice({
  slice: 'posts',
  initialState: [],
  reducers: {
    createPost(state, action) {},
    updatePost(state, action) {},
    deletePost(state, action) {}
  }
})

const { createPost } = postsSlice.actions

console.log(createPost({ id: 123, title: 'Hello World' }))
// {type : "posts/createPost", payload : {id : 123, title : "Hello World"}}
```

### 导出并使用Slices

大多数情况下,需要定义一个slice,导出action creators和reducer. 推荐的方法是使用ES6的解构和导出方法:

```javascript
const postsSlice = createSlice({
  slice: 'posts',
  initialState: [],
  reducers: {
    createPost(state, action) {},
    updatePost(state, action) {},
    deletePost(state, action) {}
  }
})

// Extract the action creators object and the reducer
const { actions, reducer } = postsSlice
// Extract and export each action creator by name
export const { createPost, updatePost, deletePost } = actions
// Export the reducer, either as a default or named export
export default reducer
```

也可以导出需要的slice部分.

通过这种方式定义的Slice和 [`"Redux Ducks pattern"`](https://github.com/erikras/ducks-modular-redux)的概念非常类似. 然而,他们也要一些潜在的问题,在导入和导出slices时需要注意.

首先,Redux action types并不是说专门只对应一个slice.
从概念上说,每个slice reducer "拥有"他们自己的一块state,例如,但是reducer应该能鉴监听任何action type并更新对应的state.例如, 很多不同的slice可能都会响应"user logger out" action, 包括清除数据,重置state为初始值等等.在设计state和创建slices是要特别当心.

第二点,JS模块在两个模块互相引用是会有"循环引用"问题. 这会导致导入变为未定义, 由此可能会中断需要导入的代码, 特别是在"ducks"或者"slices"中,如果连个slice定义在不同的问题件中,要响应定义在另一个文件中断额action是可能会出问题.

<iframe sandbox="allow-forms allow-scripts allow-same-origin allow-modals allow-popups allow-presentation" src="https://rw7ppj4z0m.codesandbox.io/" id="sandbox" title="Redux Starter Kit: Circular Slice Dependencies Example" class="sc-kAzzGY dNSBma" style="opacity: 1; z-index: 1; background-color: white; pointer-events: initial;"></iframe>

如果你碰到这个问题, 可以需要重构代码避免循环引用.

## 完