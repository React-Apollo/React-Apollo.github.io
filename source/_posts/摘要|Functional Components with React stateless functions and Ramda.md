---
title: 摘要|Functional Components with React stateless functions and Ramda
date: 2018-03-08 09:59:14
categories: 技术备忘
tags: [FP,Ramda,React]
---
>[原文在这里](https://medium.com/@mirkomariani/functional-components-with-react-stateless-functions-and-ramda-e83e54fcd86b). 有段时间不看了, 有些忘了,有些地方还有一定的加深.
## 什么是 React  stateless function?

es6的语法

```js
class List extends React.Component {
  render() {
    return (<ul>{this.props.children}</ul>);
  }
}
```

简单的 javascripg函数也可以!

```js
//Stateless function syntax
const List = function(children) {
  return (<ul>{children}</ul>);
};

//ES6 arrow syntax
const List = (children) => (<ul>{children}</ul>);
```

>彻底的模板,没有自己任何的数据,也没有生命周期方法. 纯粹依赖于输入.


### 首先来定义一个 App Container
`目的是最为一个函数接收 app sate 对象`

```js
import React from 'react';
import ReactDOM from 'react-dom';

const App = appState => (<div className="container">
  <h1>App name</h1>
  <p>Some children here...</p>
</div>);
//这里定义了渲染的方法,作为 APP函数的属性,并且是柯理化的, 等待传入 dom 元素
App.render = R.curry((node, props) => ReactDOM.render(<App {...props}/>, node));

export default App;
```

`在纯函数中,state 必须要在外部管理,然后以 props 的形式传递给组件`.
下面看看这个解释的例子
####  Stateless Timer component
简单的 timer 组件只接受 secondsElapsed 参数:

```js
import React from 'react';

export default ({ secondsElapsed }) => (<div className="well">
  Seconds Elapsed: {secondsElapsed}
</div>);
```

添加到 APP 中

```js
import React from 'react';
import ReactDOM from 'react-dom';
import R from 'ramda';
import Timer from './timer';

const App = appState => (<div className="container">
  <h1>App name</h1>
  //Timer 只从父组件接受 props 作为自己的数据
  <Timer secondsElapsed={appState.secondsElapsed} />
</div>);

App.render = R.curry((node, props) => ReactDOM.render(<App {...props}/>, node));

export default App;
```


最后创建main.js 文件,启动渲染过程

```
import App from './components/app'; //导入容器组件

// 我们已经有了柯理化的方法
//App.render = R.curry((node, props) => ReactDOM.render(<App {...props}/>, node));
//配置好渲染的目标元素
const render = App.render(document.getElementById('app'));
//state 初始值
let appState = {
  secondsElapsed: 0
};

//first render 首次渲染
render(appState);
//多次重复渲染
setInterval(() => {
  appState.secondsElapsed++;
  render(appState);
}, 1000);
```


对于上面的代码, 变化的是组件的 state, 渲染的目标元素是一直不变的, 所以我们用柯理化配置好一个工厂函数

```js
//闭包再工作!
const render = App.render(document.getElementById(‘app’));
```

柯理化返回的函数,等待传入 props


```js
(props) => ReactDOM.render(...)
```

只要 State发生变化,我们需要渲染时,只需要传递 state 就可以了

```js
setInterval(() => {
  appState.secondsElapsed++;
  render(appState);
}, 1000);
```

每一秒钟, secondsElapsed 属性会递增1, 然后作为参数传递给 render 函数

现在可以实现 Redux 风格的 reduce 函数, reduce式的函数不能突变当前值

```js
currentState->newState
```

使用 Radma 的 Lenses 来实现

```js
const secondsElapsedLens = R.lensProp('secondsElapsed');
const incSecondsElapsed = R.over(secondsElapsedLens, R.inc);

setInterval(() => {
  appState = incSecondsElapsed(appState);
  render(appState);
}, 1000);
```

首先创建 `Lens`:

```js
const secondsElapsedLens = R.lensProp('secondsElapsed');
```

lens可以聚焦于给定的属性,不会针对特定的对象, 所以可以重用. 

- `View`

```js
R.view(secondsElapsedLens, { secondsElapsed: 10 });  //=> 10
```

- `Set`

```js
R.set(secondsElapsedLens, 11, { secondsElapsed: 10 });  //=> 11
```

- `用给定的函数 Set`

```js
R.over(secondsElapsedLens, R.inc, { secondsElapsed: 10 });  //=> 11
```

inSecondElapsed  reducer 是一个偏应用函数(partial application),
这一行
```js
const incSecondsElapsed = R.over(secondsElapsedLens, R.inc);
```

会返回一个新的函数,一旦用appState 调用, 就会应用 R.inc在 lensed prop secondElapsed 上.

```js
appState=incSecondElapsed(appState)
```

## 组合 React stateless components

开篇提到,React 组件可以作为函数, 那么可以用 R.compose来 compose 这些函数吗?
当然是可以的

用 React.createClass 是这样的:

```js
const TodoList = React.createClass({
  render: function() {
    const createItem = function(item) {
      return (<li key={item.id}>{item.text}</li>);
    };

    return (<div className="panel panel-default">
      <div className="panel-body">
        <ul>
          {this.props.items.map(createItem)}
        </ul>
      </div>
    </div>);
  }
});
```

现在问题是: TodoList 可以由小的可重用部分 composition 而成吗? 可以的. 可以分为三个更小的组件

-  容器组件

```js
const Container = children => (<div className="panel panel-default">
  <div className="panel-body">
    {children}
  </div>
</div>);
```

- 列表组件

```js
const List = children => (<ul>
  {children}
</ul>);
```

-  列表项组件

```js
const ListItem = ({ id, text }) => (<li key={id}>
  <span>{text}</span>
</li>);
```

现在一步一动,看看每一步的输出

```
Container(<h1>Hello World!</h1>);

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <h1>Hello World!</h1>
 *    </div>
 *  </div>
 */

Container(List(<li>Hello World!</li>));

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <ul>
 *        <li>Hello World!</li>
 *      </ul>
 *    </div>
 *  </div>
 */

const TodoItem = {
  id: 123,
  text: 'Buy milk'
};
Container(List(ListItem(TodoItem)));

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <ul>
 *        <li>
 *          <span>Buy milk</span>
 *        </li>
 *      </ul>
 *    </div>
 *  </div>
 */
``` 
 

-  Container(List(ListItem(TodoItem)))
这里我们把TodoItem 数据传给 ListItem, 然后结果作为 List 的参数, 返回的结果又作为 Container的参数

如果用 compose 函数,过程如下

```js
R.compose(Container, List)(<li>Hello World!</li>);

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <ul>
 *        <li>Hello World!</li>
 *      </ul>
 *    </div>
 *  </div>
 */

const ContainerWithList = R.compose(Container, List);
R.compose(ContainerWithList, ListItem)({id: 123, text: 'Buy milk'});

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <ul>
 *        <li>
 *          <span>Buy milk</span>
 *        </li>
 *      </ul>
 *    </div>
 *  </div>
 */

const TodoItem = {
  id: 123,
  text: 'Buy milk'
};
const TodoList = R.compose(Container, List, ListItem);
TodoList(TodoItem);

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <ul>
 *        <li>
 *          <span>Buy milk</span>
 *        </li>
 *      </ul>
 *    </div>
 *  </div>
 */

``` 


- const TodoList = R.compose(Container, List, ListItem)

列表的工厂函数,TodoList 组件可以看作为Container,List和 ListItem 的组合
现在 还只能接受一个参数, 需要可以接受一个数组

```js
const mapTodos = function(todos) {
  return todos.map(function(todo) {
    return ListItem(todo);
  });
};
const TodoList = R.compose(Container, List, mapTodos);
const mock = [
  {id: 1, text: 'One'},
  {id: 1, text: 'Two'},
  {id: 1, text: 'Three'}
];
TodoList(mock);

/**
 *  <div className="panel panel-default">
 *    <div className="panel-body">
 *      <ul>
 *        <li>
 *          <span>One</span>
 *        </li>
 *        <li>
 *          <span>Two</span>
 *        </li>
 *        <li>
 *          <span>Three</span>
 *        </li>
 *      </ul>
 *    </div>
 *  </div>
 */
```

- mapTodos 可以有更简单的模式

```js
//This
return todos.map(function(todo) {
  return ListItem(todo);
});

//Is the same as
return todos.map(ListItem);

//So the result would be
const mapTodos = function(todos) {
  return todos.map(ListItem);
};

//The same using Ramda
const mapTodos = function(todos) {
  return R.map(ListItem, todos);
};

//Now remember two things from Ramda docs:
// - Ramda functions are automatically curried
// - The parameters to Ramda functions are arranged to make it convenient for currying.
//   The data to be operated on is generally supplied last.
//So:
const mapTodos = R.map(ListItem);

//At this point mapTodos variable is rendudant, we don't need it anymore:
const TodoList = R.compose(Container, List, R.map(ListItem));
```

-  const mapTodos = R.map(ListItem); Ramda 函数式自动柯理化的,所以代码是这样的,  等待传递数据数组,返回的数组的形式是<Li>{data.item}</Li>组成的数组


### 完整的 TodoList 的代码就是

```js
import React from 'React';
import R from 'ramda';

const Container = children => (<div className="panel panel-default">
  <div className="panel-body">
    {children}
  </div>
</div>);

const List = children => (<ul>
  {children}
</ul>);

const ListItem = ({ id, text }) => (<li key={id}>
  <span>{text}</span>
</li>);

const TodoList = R.compose(Container, List, R.map(ListItem));

export default TodoList;
```

工厂配置好了,就等数据了

-  模拟一下 appState 的 todo 数据

```js
let appState = {
  secondsElapsed: 0,
  todos: [
    {id: 1, text: 'Buy milk'},
    {id: 2, text: 'Go running'},
    {id: 3, text: 'Rest'}
  ]
};
```

-  在 App 组件中添加 TodoList 组件作为子组件

```js
import TodoList from './todo-list';
const App = appState => (<div className="container">
  <h1>App name</h1>
  <Timer secondsElapsed={appState.secondsElapsed} />
  <TodoList todos={appState.todos} />
</div>);
```

TodoList组件期待的参数是一个todos数组, 

```js
<TodoList todos={appState.todos} />
//const TodoList = R.compose(Container, List, R.map(ListItem))
```


React  stateless component是作为函数的,所以我们也可以传递参数

```js
TodoList({todos: appState.todos});
```

最好是传递单个参数,所以这种情况,再改进一下

```js
const TodoList = R.compose(Container, List, R.map(ListItem), R.prop('todos'));
```

调用就直接改为:

```
TodoList(appState)
```


>结束







