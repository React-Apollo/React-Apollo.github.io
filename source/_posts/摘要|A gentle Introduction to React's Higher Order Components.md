---
title: 摘要|A gentle Introduction to React's Higher Order Components
date: 2018-02-12 18:02:51
categories: 技术备忘
tags: [React,hoc]
---

{{TOC}}

>原文在[A gentle Introduction to React's Higher Order Components](https://www.robinwieruch.de/gentle-introduction-higher-order-components/?utm_source=mybridge&utm_medium=blog&utm_campaign=read_more)
副标题是:如何在在高阶组件中使用条件性渲染


Higher order components缩写为 HOCs.可以用于各种用例, 这里集中在条件性渲染上.

### 不断增长的组件
假设有给`TodoList`组件,实例代码如下:

```js
function App(props) {
  return (
    <TodoList todos={props.todos} />
  );
}

function TodoList({ todos }) {
  return (
    <div>
      {todos.map(todo => <TodoItem key={todo.id} todo={todo} />)}
    </div>
  );
}
```

实际编程中,光有这些是远远不够的, 需要有为空, 长度为0,渲染中的状态

```js
function TodoList({ todos, isLoadingTodos }) {
  if (isLoadingTodos) {
    return (
      <div>
        <p>Loading todos ...</p>
      </div>
    );
  }

  if (!todos) {
    return null;
  }

  if (!todos.length) {
    return (
      <div>
        <p>You have no Todos.</p>
      </div>
    );
  }

  return (
    <div>
      {todos.map(todo => <TodoItem key={todo.id} todo={todo} />)}
    </div>
  );
}
```

由此代码就显得复杂了.高阶组件可以让这个问题简化一下. 

### 导入高阶组件

HOCS通常接收一个组件和可选的参数,然后返回一个输入组件(input component)的增强版本(enhanced components). 
#### 定义第一个高阶组件 withTodosNull

高阶组件返回 stateless-component或者 ES6 class 组件都可以,如果需要访问组件生命周期中的方法,或者是`this.state`,应该要返回一个 ES6 class 组件

```js
function withTodosNull(Component) {
  return function (props) {
    return !props.todos
      ? null
      : <Component { ...props } />
  }
}
```

这是一个`三元操作符`,高阶组件根据 props 来决定是渲染null 还是组件本身.所有的 props 都向下传递.  

改为 ES6的箭头函数,更容易理解:

```js
const withTodosNull = (Component) => (props) =>
  !props.todos
    ? null
    : <Component { ...props } />
```

最终的高阶函数完成了:

```js
const withTodosNull = (Component) => (props) =>
  ...

function TodoList({ todos }) {
  ...
}

const TodoListWithNull = withTodosNull(TodoList);

function App(props) {
  return (
    <TodoListWithNull todos={props.todos} />
  );
}
```

与 null 组件类似

```js
const withTodosEmpty = (Component) => (props) =>
  !props.todos.length
    ? <div><p>You have no Todos.</p></div>
    : <Component { ...props } />

const withLoadingIndicator = (Component) => (props) =>
  props.isLoadingTodos
    ? <div><p>Loading todos ...</p></div>
    : <Component { ...props } />
```

如果在 input 子类的组件中使用 loading 时, 并不需要出传递其他的 props,可以用 ES6 的展开操作符 把 props 分割一下:

```js
const withLoadingIndicator = (Component) => ({ isLoadingTodos, ...others }) =>
  isLoadingTodos
    ? <div><p>Loading todos ...</p></div>
    : <Component { ...others } />
```

最终在`TodoList`组件中的使用:

```js
const withTodosNull = (Component) => (props) =>
  ...

const withTodosEmpty = (Component) => (props) =>
  ...

const withLoadingIndicator = (Component) => ({ isLoadingTodos, ...others }) =>
  ...

function TodoList({ todos }) {
  ...
}

const TodoListOne = withTodosEmpty(TodoList);
const TodoListTwo = withTodosNull(TodoListOne);
const TodoListThree = withLoadingIndicator(TodoListTwo);

function App(props) {
  return (
    <TodoListThree
      todos={props.todos}
      isLoadingTodos={props.isLoadingTodos}
    />
  );
}
```

高阶组件中的顺序也很重要,因为,前一个组件的条件满足,就直接返回了.

#### 使用 Recompose 进一步改进代码

```js
import { compose } from 'recompose';

...

const withConditionalRenderings = compose(
  withLoadingIndicator,
  withTodosNull,
  withTodosEmpty
);
```


这个增强的过程就是:

```js
const TodoListWithConditionalRendering = withConditionalRenderings(TodoList);
```

```js
import { compose } from 'recompose';

const withTodosNull = (Component) => (props) =>
  ...

const withTodosEmpty = (Component) => (props) =>
  ...

const withLoadingIndicator = (Component) => ({ isLoadingTodos, ...others }) =>
  ...

function TodoList({ todos }) {
  ...
}

const withConditionalRenderings = compose(
  withLoadingIndicator,
  withTodosNull,
  withTodosEmpty
);

const TodoListWithConditionalRendering = withConditionalRenderings(TodoList);

function App(props) {
  return (
    <TodoListWithConditionalRendering
      todos={props.todos}
      isLoadingTodos={props.isLoadingTodos}
    />
  );
}
```

#### 重用抽象的高阶组件
上面的组件适应于特定的渲染, 不能用在其他地方. 考虑到长期的使用,应该抽象出来,以便于其他的组价也可以使用

在`withTodoNull`中添加一个 optional 负载,这个负载是一个函数,负责返回 true 或者 false, 用于决定最终的渲染结果:

```js
const withTodosNull = (Component, conditionalRenderingFn) => (props) =>
  conditionalRenderingFn(props)
    ? null
    : <Component { ...props } />
```

现在这个函数的名字就有点误导了, 改为:

```js
const withCondition = (Component, conditionalRenderingFn) => (props) =>
  conditionalRenderingFn(props)
    ? null
    : <Component { ...props } />
```

现在就可以用这个抽象的条件判断组件来实现具体的逻辑

```js
const withCondition = (Component, conditionalRenderingFn) => (props) =>
  conditionalRenderingFn(props)
    ? null
    : <Component { ...props } />

const conditionFn = (props) => !props.todos;

const TodoListWithCondition = withCondition(TodoList, conditionFn);
```

为了利于实现柯理化, 把负载的函数也分开传递:

```js
const withCondition = (conditionalRenderingFn) => (Component) => (props) =>
    conditionalRenderingFn(props)
        ? null
        : <Component { ...props } />
```


在使用时传递条件函数就可以了:

```js
import { compose } from 'recompose';

...

const conditionFn = (props) => !props.todos;

const withConditionalRenderings = compose(
    withLoadingIndicator,
    withCondition(conditionFn),
    withTodosEmpty
);

const TodoListWithConditionalRendering = withConditionalRenderings(TodoList);
```

#### maybe 和 either 高阶组件
什么也不返回,或者返回输入组件的类型,在函数式编程中有名字的叫 Maybe. 
```js
const withMaybe = (conditionalRenderingFn) => (Component) => (props) =>
  conditionalRenderingFn(props)
    ? null
    : <Component { ...props } />
```

两个组件返回其一的在函数式编程中称为 either

```js
const withEither = (conditionalRenderingFn, EitherComponent) => (Component) => (props) =>
  conditionalRenderingFn(props)
    ? <EitherComponent />
    : <Component { ...props } />
```


####  最最终的版本
终于是最后一个版本了
```
import { compose } from 'recompose';

const withMaybe = (conditionalRenderingFn) => (Component) => (props) =>
  conditionalRenderingFn(props)
    ? null
    : <Component { ...props } />

const withEither = (conditionalRenderingFn, EitherComponent) => (Component) => (props) =>
  conditionalRenderingFn(props)
    ? <EitherComponent />
    : <Component { ...props } />

const EmptyMessage = () =>
  <div>
    <p>You have no Todos.</p>
  </div>

const LoadingIndicator = () =>
  <div>
    <p>Loading todos ...</p>
  </div>

const isLoadingConditionFn = (props) => props.isLoadingTodos;
const nullConditionFn = (props) => !props.todos;
const isEmptyConditionFn = (props) => !props.todos.length

const withConditionalRenderings = compose(
  withEither(isLoadingConditionFn, LoadingIndicator),
  withMaybe(nullConditionFn),
  withEither(isEmptyConditionFn, EmptyMessage)
);

const TodoListWithConditionalRendering = withConditionalRenderings(TodoList);

function App(props) {
  return (
    <TodoListWithConditionalRendering
      todos={props.todos}
      isLoadingTodos={props.isLoadingTodos}
    />
  );
}

function TodoList({ todos }) {
  return (
    <div>
      {todos.map(todo => <TodoItem key={todo.id} todo={todo} />)}
    </div>
  );
}
```

确实赏心悦目的代码改进,  每一步都体现了程序员的思考过程.  


