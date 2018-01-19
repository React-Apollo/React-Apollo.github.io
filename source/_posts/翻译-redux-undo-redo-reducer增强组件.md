---
title: 翻译|redux undo/redo  reducer增强组件
date: 2017-04-04 13:18:28
categories: 翻译
tags: Redux
---

>Redux的文档中提供一个可以做undo/redo的解决办法,实际是有previous,current,prew的对象,围绕这数据的压入和弹出来实现操作步骤的记忆,结合persist就可以实现更强大的记忆功能.今天的这个增强组件实际把这个功能给包装了一下,内部实现细节仍然没有变.只需要把reducer用这个增强组件包装一下就可以用了.


#  redux undo/redo
![](https://ww1.sinaimg.cn/large/006tNc79ly1feb2dpdu5xg30eo01k0t1.gif)

提示:你可以使用[redux-undo-boilerplate](https://github.com/omnidan/redux-undo-boilerplate)来开始项目.

## Installation
```
npm install --save redux-undo
```

## API

```
import undoable from 'redux-undo';
undoable(reducer)
undoable(reducer, config)
```

## 让你的reducers变得可以重做
`redux-undo`是一个reducer增强组件,它提供了`undoable`函数,这个函数接收已经存在的reducer和配置对象,使用undo函数增强已经存在的reducer.

**注意：**如果在`state.counter`之前接入,你必须要在包装`reducer`之后接入`state.coutner.present`.

首先导入`redux-undo`
```
 // Redux utility functions 
import { combineReducers } from 'redux';
// redux-undo higher-order reducer 
import undoable from 'redux-undo';
```

接着,添加`undoable`到你的reducer
```
combineReducers({
  counter: undoable(counter)
})
```

`配置项`想这样传递
```
combineReducers({
  counter: undoable(counter, {
    limit: 10 // set a limit for the history 
  })
})
```

## 历史API

使用reducer包装你的reducer想这样
```
 {
  past: [...pastStatesHere...],
  present: {...currentStateHere...},
  future: [...futureStatesHere...]
}
```

现在你可以使用`state.present`获取当前的state
获取所有过去的state使用`state.past`.

## Undo/Redo Actions

首先导入undo/redo action creators
```
import { ActionCreators } from 'redux-undo';
```

然后就可以使用`store.dispatch()`和undo/redo action creators来执行undo/redo操作.
```
store.dispatch(ActionCreators.undo()) // undo the last action 
store.dispatch(ActionCreators.redo()) // redo the last action 
 
store.dispatch(ActionCreators.jumpToPast(index)) // jump to requested index in the past[] array 
store.dispatch(ActionCreators.jumpToFuture(index)) // jump to requested index in the future[] array 
```

## 配置
配置对象传递给`undoable()`(值是默认值)

```
undoable(reducer, {
  limit: false, // set to a number to turn on a limit for the history 
 
  filter: () => true, // see `Filtering Actions` section 
 
  undoType: ActionTypes.UNDO, // define a custom action type for this undo action 
  redoType: ActionTypes.REDO, // define a custom action type for this redo action 
 
  jumpToPastType: ActionTypes.JUMP_TO_PAST, // define custom action type for this jumpToPast action 
  jumpToFutureType: ActionTypes.JUMP_TO_FUTURE, // define custom action type for this jumpToFuture action 
 
  initialState: undefined, // initial state (e.g. for loading) 
  initTypes: ['@@redux/INIT', '@@INIT'] // history will be (re)set upon init action type 
  initialHistory: { // initial history (e.g. for loading) 
    past: [],
    present: config.initialState,
    future: []
  },
 
  debug: false, // set to `true` to turn on debugging 
})
```

## 过滤Actions
如果你不想包含每一步的action,可以传递一个函数到`undoable`
```
undoable(reducer, function filterActions(action, currentState, previousState) {
  return action.type === SOME_ACTION; // only add to history if action is SOME_ACTION只有some_action的action才能记录 
})
 
// or you could do... 
 
undoable(reducer, function filterState(action, currentState, previousState) {
  return currentState !== previousState; // only add to history if state changed只有state变化的才能记录重做 
})
```

或者你可以使用`distinctState`,`includeAction`,`excludeAction`助手函数
```
import undoable, { distinctState, includeAction, excludeAction } from 'redux-undo';
```

现在你可以使用助手函数了,相当简单
```
undoable(reducer, { filter: includeAction(SOME_ACTION) })
undoable(reducer, { filter: excludeAction(SOME_ACTION) })
 
// or you could do... 
 
undoable(reducer, { filter: distinctState() })
```

甚至还支持数组
```
 undoable(reducer, { filter: includeAction([SOME_ACTION, SOME_OTHER_ACTION]) })
undoable(reducer, { filter: excludeAction([SOME_ACTION, SOME_OTHER_ACTION]) })
```

## 有什么魔法？怎么工作的
Redux文档中的[`实现Undo历史的方案`](https://rackt.github.io/redux/docs/recipes/ImplementingUndoHistory.html)解释了redux-undo工作的具体细节.