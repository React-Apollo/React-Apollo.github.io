

---
title: 翻译|Getting Started with React, Redux and Immutable: a Test-Driven Tutorial (Part 2)
date: 2017-03-26 15:01:24
categories: 技术备忘
tags: [React,redux,Immutable.js]
---


翻译版本,[原文请见](http://www.theodo.fr/blog/2016/03/getting-started-with-react-redux-and-immutable-a-test-driven-tutorial-part-2/)


这是第二部分的内容.

在第一部分,我们罗列了app的UI,开发和单元测试的基础.

我们看到了app的state通过React的`props`向下传递到单个的组件,用户的actions声明为回调函数,因此app的逻辑和UI分离开来了.

## Redux的工作流介绍
在这一点上,我们的UI是没有交互操作的:尽管我们已经测试了如果一个item如果被设定为`completed`,它将给文本划线,但是这里还没有方法邀请用户来完成它:
1. state tree通过`props`定义了UI和action回调函数.
2. 用户的actions,例如点击,被发送到action creator,action被它范式化.
3. redux action被传递到reducer实现实际的app逻辑
4. reducer更新state tree,dispatch state到store.
5. UI根据store里的新state tree来更新UI

![Redux working flos](https://ww3.sinaimg.cn/large/006tNc79ly1fdua9bq152j30f10870sn.jpg)

## 设定初始化state
[这部分的代码提交在这里](https://github.com/phacks/redux-todomvc/commit/be48d4d610b3438aeb1dfcd07d317b3c72fbdb3e)

我们的第一个action将会允许我们在Redux store里正确的设置初始化state
,我们将会创建store.

Redux中的action是一个信息的载体(payload).action由一个JSON对象有一个`type`属性,描述action到底是做什么的,还有一部分是app需要的信息.在我们的实例中,type被设定为`SET_STATE`,我们可以添加一个state对象包含需要的state:
```
{
  type: 'SET_STATE',
  state: {
    todos: [
      {id: 1, text: 'React', status: 'active', editing: false},
      {id: 2, text: 'Redux', status: 'active', editing: false},
      {id: 3, text: 'Immutable', status: 'active', editing: false},
    ],
    filter: 'all'
  }
}
```

这个action会被dispatch到一个reducer,reducer角色的是识别和实施和action对应的逻辑代码.

让我们为reducer来写单元测试代码
`test/reducer_spec.js`
```
 import {List, Map, fromJS} from 'immutable';
import {expect} from 'chai';

import reducer from '../src/reducer';

describe('reducer', () => {

  it('handles SET_STATE', () => {
    const initialState = Map();
    const action = {
      type: 'SET_STATE',
      state: Map({
        todos: List.of(
          Map({id: 1, text: 'React', status: 'active'}),
          Map({id: 2, text: 'Redux', status: 'active'}),
          Map({id: 3, text: 'Immutable', status: 'completed'})
        )
      })
    };

    const nextState = reducer(initialState, action);

    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'completed'}
      ]
    }));
  });

});
```
为了方便一点,`state`使用单纯JS对象,而不是使用Immutable数据结构.让我们的reducer来处理转变.最后,reducer将会优雅的处理`undefined`初始化state:
`test/reducer_spec.js`
```
 // ...
describe('reducer', () => {
  // ...
  it('handles SET_STATE with plain JS payload', () => {
    const initialState = Map();
    const action = {
      type: 'SET_STATE',
      state: {
        todos: [
          {id: 1, text: 'React', status: 'active'},
          {id: 2, text: 'Redux', status: 'active'},
          {id: 3, text: 'Immutable', status: 'completed'}
        ]
      }
    };
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'completed'}
      ]
    }));
  });

  it('handles SET_STATE without initial state', () => {
    const action = {
      type: 'SET_STATE',
      state: {
        todos: [
          {id: 1, text: 'React', status: 'active'},
          {id: 2, text: 'Redux', status: 'active'},
          {id: 3, text: 'Immutable', status: 'completed'}
        ]
      }
    };
    const nextState = reducer(undefined, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'completed'}
      ]
    }));
  });
});
```

我们的reducer将会匹配接收的actions的`type`,如果type是`SET_STATE`,当前的state和action运载的state融合在一起:
`src/reducer.js`
```js
import {Map} from 'immutable';

function setState(state, newState) {
  return state.merge(newState);
}

export default function(state = Map(), action) {
  switch (action.type) {
    case 'SET_STATE':
      return setState(state, action.state);
  }
  return state;
}
```
现在我们不得不把reducer连接到我们的app,所以当app启动初始化state.这里实际是第一次使用Redux库,安装一下
`npm install —save redux@3.3.1 react-redux@4.4.1`

`src/index.jsx`
```js
 import React from 'react';
import ReactDOM from 'react-dom';
import {List, Map} from 'immutable';
import {createStore} from 'redux';
import {Provider} from 'react-redux';
import reducer from './reducer';
import {TodoAppContainer} from './components/TodoApp';

// We instantiate a new Redux store
const store = createStore(reducer);
// We dispatch the SET_STATE action holding the desired state
store.dispatch({
  type: 'SET_STATE',
  state: {
    todos: [
      {id: 1, text: 'React', status: 'active', editing: false},
      {id: 2, text: 'Redux', status: 'active', editing: false},
      {id: 3, text: 'Immutable', status: 'active', editing: false},
    ],
    filter: 'all'
  }
});

require('../node_modules/todomvc-app-css/index.css');

ReactDOM.render(
  // We wrap our app in a Provider component to pass the store down to the components
  <Provider store={store}>
    <TodoAppContainer />
  </Provider>,
  document.getElementById('app')
);

```

如果你看看上面的代码段,你可以注意到我们的`TodoApp`组件实际是被`TodoAppContainer`代替.在Redux里,有两种类型的组件:展示组件和容器.我推荐你阅读一下由Dan Abramov(Redux的作者)写作的[高信息量的文章](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0#.e5z2vws8e),强调了展示组件和容器的差异性.

如果我想总结得快一点,我将引用[Redux 文档](http://redux.js.org/docs/basics/UsageWithReact.html)的内容：

“展示组件是关于事件的样子(模板和样式),容器组件是关于事情是怎么工作的(数据获取,state更新)”.

所以我们创建store,传递给`TodoAppContainer`.然而为了子组件可以使用store,我们把state映射成为React组件`TodoApp`的`props`.
`src/components/TodoApp.jsx`
```js
 // ...
import {connect} from 'react-redux';

export class TodoApp extends React.Component {
// ...
}
function mapStateToProps(state) {
  return {
    todos: state.get('todos'),
    filter: state.get('filter')
  };
}

export const TodoAppContainer = connect(mapStateToProps)(TodoApp);
```

如果你在浏览器中重新加载app,你应该可以看到它初始化和之前一样,不过现在使用Redux tools.

## Redux dev 工具

[这一部分的提交代码](https://github.com/phacks/redux-todomvc/commit/9e82a2bf7ffaea5d0fda6af361a126517aecc115)

现在我们已经配置了redux store和reducer.我们可以配置Redux dev tools来展现数据流开发.

首先,获取[Redux dev tools Chrome extension](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd)

dev tools可以在Store创建的时候可以加载.

`src/index.jsx`
```js
 // ...
import {compose, createStore} from 'redux';

const createStoreDevTools = compose(
  window.devToolsExtension ? window.devToolsExtension() : f => f
)(createStore);
const store = createStoreDevTools(reducer);
// ...
```

![Redux dev tools](https://ww2.sinaimg.cn/large/006tNc79ly1fdubya02s9j31cy0v6dgk.jpg)

重新加载app,点击Redux图标,有了.

有三个不同的监视器可以使用:Diff监视器,日志监视器,Slider监视器.

## 使用Action Creators配置我们的actions
切换item的不同状态.

[这部分的提交代码在这里](https://github.com/phacks/redux-todomvc/commit/7a2dc0963684b569c11f92e41a324324dfb21bdc)

下一步是允许用户在`active`和`completed`之前切换状态：
`test/reducer_spec.js`
```js
 import {List, Map, fromJS} from 'immutable';
import {expect} from 'chai';

import reducer from '../src/reducer';

describe('reducer', () => {
// ...
  it('handles TOGGLE_COMPLETE by changing the status from active to completed', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'completed'}
      ]
    });
    const action = {
      type: 'TOGGLE_COMPLETE',
      itemId: 1
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'completed'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'completed'}
      ]
    }));
  });

  it('handles TOGGLE_COMPLETE by changing the status from completed to active', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'completed'}
      ]
    });
    const action = {
      type: 'TOGGLE_COMPLETE',
      itemId: 3
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
        {id: 3, text: 'Immutable', status: 'active'}
      ]
    }));
  });
});
```
为了通过这些测试,我们更新reducer:
`src/reducer.js`
```js
// ...
function toggleComplete(state, itemId) {
  // We find the index associated with the itemId
  const itemIndex = state.get('todos').findIndex(
    (item) => item.get('id') === itemId
  );
  // We update the todo at this index
  const updatedItem = state.get('todos')
    .get(itemIndex)
    .update('status', status => status === 'active' ? 'completed' : 'active');

  // We update the state to account for the modified todo
  return state.update('todos', todos => todos.set(itemIndex, updatedItem));
}

export default function(state = Map(), action) {
  switch (action.type) {
    case 'SET_STATE':
      return setState(state, action.state);
    case 'TOGGLE_COMPLETE':
      return toggleComplete(state, action.itemId);
  }
  return state;
}
```

和`SET_STATE`的action同一个地方,我们需要让`TodoAppContainer`组件感知到action,所以`toggleComplete`回调函数会被传递到`TodoItem`组件(实际调用函数的地方).

在Redux中,有标准的方法来做这件事：Action Creators.

action creators是简单的函数,返回合适的action，这些韩式是React的`props`的一些映射之一.
让我们创建第一个action creator:
`src/action_creators.js`

```js
export function toggleComplete(itemId) {
  return {
    type: 'TOGGLE_COMPLETE',
    itemId
  }
}
```

现在,尽管`TodoAppcontainer`组件中的`connect`函数的调用可以用来获取store,我们告诉组件使用映射`props`的回调函数:
`src/components/TodoApp.jsx`
```js
// ...
import * as actionCreators from '../action_creators';
export class TodoApp extends React.Component {
  // ...
  render() {
    return <div>
      // ...
        // We use the spread operator for better lisibility
        <TodoList  {...this.props} />
      // ...
    </div>
  }
};

export const TodoAppContainer = connect(mapStateToProps, actionCreators)(TodoApp);
```

重启你的webserver,刷新一下你的浏览器:当当.在条目上点击现在可以切换它的状态.如果你查看Redux dev tools,你可以看到触发的action和后继的更新.

## 改变目前的过滤器

[相关代码在在这里](https://github.com/phacks/redux-todomvc/commit/3949d4f38912e4b6b8e60fc4c553614d4076028c)

现在每件事情都已经配置完毕,写其他的action是件小事.我们继续创建你希望的`CHANGE_FILTER`action,改变当前state的filter,由此仅仅显示过滤过的条目.
开始创建action creator：
`src/action_creators.js`
```js
 // ...
export function changeFilter(filter) {
  return {
    type: 'CHANGE_FILTER',
    filter
  }
}
```

现在写reducer的单元测试:
`test/reducer_spec.js`
```js
// ...
describe('reducer', () => {
  // ...
  it('handles CHANGE_FILTER by changing the filter', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
      ],
      filter: 'all'
    });
    const action = {
      type: 'CHANGE_FILTER',
      filter: 'active'
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
      ],
      filter: 'active'
    }));
  });
});

```
关联的reducer函数:
`src/reducer.js`
```js
 // ...
function changeFilter(state, filter) {
  return state.set('filter', filter);
}

export default function(state = Map(), action) {
  switch (action.type) {
    case 'SET_STATE':
      return setState(state, action.state);
    case 'TOGGLE_COMPLETE':
      return toggleComplete(state, action.itemId);
    case 'CHANGE_FILTER':
      return changeFilter(state, action.filter);
  }
  return state;
}
```
最后我们把`changeFilter`回调函数传递给`TodoTools`组件:
`TodoApp.jsx`
```js
// ...
export class TodoApp extends React.Component {
  // ...
  render() {
    return <div>
      <section className="todoapp">
        // ...
        <TodoTools changeFilter={this.props.changeFilter}
                   filter={this.props.filter}
                   nbActiveItems={this.getNbActiveItems()} />
      </section>
      <Footer />
    </div>
  }
};

```

完成了,第一个filter selector工作完美

## Item编辑

[代码在这里](https://github.com/phacks/redux-todomvc/commit/2a7b1138f778524d4aa7eac193c995258d28c5a3)
 当用户编辑一个条目,实际上是两个actions触发的三个可能性:
 * 用户输入编辑模式:`EDIT_ITEM`
 * 用户退出编辑模式(不保存变化):`CANCEL_EDITING`
 * 用户验证他的编辑(保存变化):`DONE_EDITING`

我们可以为三个actions编写action creators：
`src/action_creators.js`
```js
// ...
export function editItem(itemId) {
  return {
    type: 'EDIT_ITEM',
    itemId
  }
}

export function cancelEditing(itemId) {
  return {
    type: 'CANCEL_EDITING',
    itemId
  }
}

export function doneEditing(itemId, newText) {
  return {
    type: 'DONE_EDITING',
    itemId,
    newText
  }
}
```

现在为这些actions编写单元测试:
`test/reducer_spec.js`
```js
// ...
describe('reducer', () => {
  // ...
  it('handles EDIT_ITEM by setting editing to true', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active', editing: false},
      ]
    });
    const action = {
      type: 'EDIT_ITEM',
      itemId: 1
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active', editing: true},
      ]
    }));
  });

  it('handles CANCEL_EDITING by setting editing to false', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active', editing: true},
      ]
    });
    const action = {
      type: 'CANCEL_EDITING',
      itemId: 1
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active', editing: false},
      ]
    }));
  });

  it('handles DONE_EDITING by setting by updating the text', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active', editing: true},
      ]
    });
    const action = {
      type: 'DONE_EDITING',
      itemId: 1,
      newText: 'Redux',
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'Redux', status: 'active', editing: false},
      ]
    }));
  });
});
```

现在我们可以开发reducer函数,实际操作三个actions:
`src/reducer.js`
```js
function findItemIndex(state, itemId) {
  return state.get('todos').findIndex(
    (item) => item.get('id') === itemId
  );
}

// We can refactor the toggleComplete function to use findItemIndex
function toggleComplete(state, itemId) {
  const itemIndex = findItemIndex(state, itemId);
  const updatedItem = state.get('todos')
    .get(itemIndex)
    .update('status', status => status === 'active' ? 'completed' : 'active');

  return state.update('todos', todos => todos.set(itemIndex, updatedItem));
}

function editItem(state, itemId) {
  const itemIndex = findItemIndex(state, itemId);
  const updatedItem = state.get('todos')
    .get(itemIndex)
    .set('editing', true);

  return state.update('todos', todos => todos.set(itemIndex, updatedItem));
}

function cancelEditing(state, itemId) {
  const itemIndex = findItemIndex(state, itemId);
  const updatedItem = state.get('todos')
    .get(itemIndex)
    .set('editing', false);

  return state.update('todos', todos => todos.set(itemIndex, updatedItem));
}

function doneEditing(state, itemId, newText) {
  const itemIndex = findItemIndex(state, itemId);
  const updatedItem = state.get('todos')
    .get(itemIndex)
    .set('editing', false)
    .set('text', newText);

  return state.update('todos', todos => todos.set(itemIndex, updatedItem));
}

export default function(state = Map(), action) {
  switch (action.type) {
    // ...
    case 'EDIT_ITEM':
      return editItem(state, action.itemId);
    case 'CANCEL_EDITING':
      return cancelEditing(state, action.itemId);
    case 'DONE_EDITING':
      return doneEditing(state, action.itemId, action.newText);
  }
  return state;
}
```

## 清除完成,添加和删除条目
[代码在这里](https://github.com/phacks/redux-todomvc/commit/c89059a6767903fdf8b9827209f92e1f7385bdb7)

三个剩下的action是:
1. `CLEAR_COMPLETED`,在`TodoTools`组件中触发,从列表中清除完成的条目
2. `ADD_ITEM`,在`TodoHeader`中触发,根据用户的的输入文本来添加条目
3. `DELETE_ITEM`,相似`TodoItem`中调用,删除一个条目

我们现在使用的工作流是:添加action creators,单元测试reducer和代码逻辑,最终通过props传递回调函数:
`src/action_creators.js`

```js
// ...
export function clearCompleted() {
  return {
    type: 'CLEAR_COMPLETED'
  }
}

export function addItem(text) {
  return {
    type: 'ADD_ITEM',
    text
  }
}

export function deleteItem(itemId) {
  return {
    type: 'DELETE_ITEM',
    itemId
  }
}
```


`test/reducer_spec.js`
```js
 // ...
describe('reducer', () => {
  // ...
  it('handles CLEAR_COMPLETED by removing all the completed items', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'completed'},
      ]
    });
    const action = {
      type: 'CLEAR_COMPLETED'
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
      ]
    }));
  });

  it('handles ADD_ITEM by adding the item', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'}
      ]
    });
    const action = {
      type: 'ADD_ITEM',
      text: 'Redux'
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'active'},
      ]
    }));
  });

  it('handles DELETE_ITEM by removing the item', () => {
    const initialState = fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
        {id: 2, text: 'Redux', status: 'completed'},
      ]
    });
    const action = {
      type: 'DELETE_ITEM',
      itemId: 2
    }
    const nextState = reducer(initialState, action);
    expect(nextState).to.equal(fromJS({
      todos: [
        {id: 1, text: 'React', status: 'active'},
      ]
    }));
  });
});

```

`src/reducer.js`
```js
function clearCompleted(state) {
  return state.update('todos',
    (todos) => todos.filterNot(
      (item) => item.get('status') === 'completed'
    )
  );
}

function addItem(state, text) {
  const itemId = state.get('todos').reduce((maxId, item) => Math.max(maxId,item.get('id')), 0) + 1;
  const newItem = Map({id: itemId, text: text, status: 'active'});
  return state.update('todos', (todos) => todos.push(newItem));
}

function deleteItem(state, itemId) {
  return state.update('todos',
    (todos) => todos.filterNot(
      (item) => item.get('id') === itemId
    )
  );
}

export default function(state = Map(), action) {
  switch (action.type) {
    // ...
    case 'CLEAR_COMPLETED':
      return clearCompleted(state);
    case 'ADD_ITEM':
      return addItem(state, action.text);
    case 'DELETE_ITEM':
      return deleteItem(state, action.itemId);
  }
  return state;
}

```

`src/components/TodoApp.jsx`
```js
 // ...
export class TodoApp extends React.Component {
  // ...
  render() {
    return <div>
      <section className="todoapp">
        // We pass down the addItem callback
        <TodoHeader addItem={this.props.addItem}/>
        <TodoList {...this.props} />
        // We pass down the clearCompleted callback
        <TodoTools changeFilter={this.props.changeFilter}
                    filter={this.props.filter}
                    nbActiveItems={this.getNbActiveItems()}
                    clearCompleted={this.props.clearCompleted}/>
      </section>
      <Footer />
    </div>
  }
};
```

我们的TodoMVC app现在完成了.

## 包装起来
这我们的测试驱动的React,Redux&Immutable 技术栈

如果你想了解更多内容,有更多的事情等着你去挖掘
例如:
* [React Redux router](https://github.com/reactjs/react-router-redux)创建完全的单页面应用
* 是由Redux在后台同构Redux,看这[1教程](http://teropa.info/blog/2015/09/10/full-stack-redux-tutorial.html),[2教程](https://blog.diacode.com/trello-clone-with-phoenix-and-react-pt-1)
* [Gambie](https://github.com/Ghirro/gambit),简单的包装器简化到API的连接
* [系列视频](https://egghead.io/series/getting-started-with-redux),作者是Dan Abramov(Redux的创建者)
* Redux [网站上更多的内容](http://redux.js.org/docs/introduction/Ecosystem.html)!



