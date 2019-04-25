---
title: 摘要| Recompose 文档
date: 2018-02-26 13:30:14
categories: 技术备忘
tags: [HOC,FP]
---

{{TOC}}

# Recompose API

在文档中, HOC 指的是一个函数接收一个 React 组件,返回另一个新的 React 组件

```js
   const EnhancedComponent=hoc(BaseComponent)
```

有时是可以组合的

```js
const composedHoc=compose(hoc1,hoc2,hoc3)
//等同于
const composedHoc=BaseComponent=>hoc1(hoc2(hoc3(BaseComponent)))
```

绝大多数的 Recompose 助手函数都是返回 hoc的函数

## Higher-order components

### `mapProps`

```js
  mapProps(
    propsMapper:(ownerProps:Object)=>Object,
     ):HigherOrderComponent
```

接收一个函数,映射拥有者的 props成为新的 props 集合, 并传递给 baseComponent.
`mapProps()`和其他的函数式工具可以很好的一起工作, 例如 Recomopose 没有`omitProps()`函数,但是可以很容易的使用 lodash 的函数`omit()`

```js
const omitProps = keys => mapProps(props => omit(keys, props))

// 因为 lodash-fp 是支持柯理化的,所以也可以写为
const omitProps = compose(mapProps, omit)
```

### `withProps`

```js
withProps(
  createProps: (ownerProps: Object) => Object | Object
): HigherOrderComponent
```

新创建的props 和 owner props 合并

### `withPropsOnChange()`

```js
withPropsOnChange(
  shouldMapOrKeys: Array<string> | (props: Object, nextProps: Object) => boolean,
  createProps: (ownerProps: Object) => Object
): HigherOrderComponent
```

只有在 shouldMapKeys 发生变化时才可以创建新的 props. 确保 createProps 内的计算只有在必要的情况下才进行.


### `withHandlers()`

```js
withHandlers(
  handlerCreators: {
    [handlerName: string]: (props: Object) => Function
  } |
  handlerCreatorsFactory: (initialProps) => {
    [handlerName: string]: (props: Object) => Function
  }
): HigherOrderComponent
```

接收一组 handler creator 或者是 工厂函数. 这些函数都是高阶函数, 接收一组 props,返回操作函数

这么做,就是让 handler 通过闭包访问当前的 props,但是又不用改变函数的签名

传递给组件的handlers都是 immutable 属性, 在渲染器中会一直保持不变.这么做避免了在函数式组件中创建函数的一个缺陷, 就是原先的函数式组件中,每次渲染都会创建新的 handler,打断了使用`shouldComponentUpdate()`函数通过判读 props 变化的优化措施. 所以在创建 handler 时最好使用 `withHandlers()` ,`mapProps`和`withProps`每次会创建新的 handler

实例:

```js
const enhance = compose(
  withState('value', 'updateValue', ''),
  withHandlers({
    onChange: props => event => {
      props.updateValue(event.target.value)
    },
    onSubmit: props => event => {
      event.preventDefault()
      submitForm(props.value)
    }
  })
)

const Form = enhance(({ value, onChange, onSubmit }) =>
  <form onSubmit={onSubmit}>
    <label>Value
      <input type="text" value={value} onChange={onChange} />
    </label>
  </form>
)
```

### `defaultProps()`

```js
defaultProps(
  props: Object
): HigherOrderComponent
```

default 的 props 会和 owner props合并,但是owner props 的优先级更高,有相同属性的,不会被替换


### `renameProps()`

```js

renameProp(
  oldName: string,
  newName: string
): HigherOrderComponent
```

Rename 单个属性

### `renameProps()` :更改多个属性名


### `withState()`

```js
withState(
  stateName: string,
  stateUpdaterName: string,
  initialState: any | (props: Object) => any
): HigherOrderComponent
```

传递两个额外的 props 到 base component: state value和一个 更新 state value 的函数,  state updater 的签名如下:

```js

stateUpdater<T>((prevValue: T) => T, ?callback: Function): void
stateUpdater(newValue: any, ?callback: Function): void
```

第一个形式接收之前的state,映射为新的 state value. `withState()`和`withHadlers()`一起创建特定的 updater 函数.  例如

```js

const addCounting = compose(
  withState('counter', 'setCounter', 0),
  withHandlers({
    increment: ({ setCounter }) => () => setCounter(n => n + 1),
    decrement: ({ setCounter }) => () =>  setCounter(n => n - 1),
    reset: ({ setCounter }) => () => setCounter(0)
  })
)
```

第二种形式接收单个值, 被作为新的 state

两种形式都接受可选的参数,这个参数是一个回调函数, 一旦`setState()`完成,组件重新渲染,回调函数会执行.

初始值是必须的. 要么是 state 值, 或者是从初始 props 返回的初始 State.

### `withStateHandlers()`

```js
withStateHandlers(
  initialState: Object | (props: Object) => any,
  stateUpdaters: {
    [key: string]: (state:Object, props:Object) => (...payload: any[]) => Object
  }
)
```

传递 state对象属性和 immutable 版本的 updater 函数到 base component

每个 state updater 函数接收state,props和 payload必须返回新的 state 或者 undefined.  新的 state 和之前的 state 进行浅层比较, 如果返回 undefined,组件就不会重新渲染. 

实例:

```js
const Counter = withStateHandlers(
    ({ initialCounter = 0 }) => ({
      counter: initialCounter,
    }),
    {
      incrementOn: ({ counter }) => (value) => ({
        counter: counter + value,
      }),
      decrementOn: ({ counter }) => (value) => ({
        counter: counter - value,
      }),
      resetCounter: (_, { initialCounter = 0 }) => () => ({
        counter: initialCounter,
      }),
    }
  )(
    ({ counter, incrementOn, decrementOn, resetCounter }) =>
      <div>
        <Button onClick={() => incrementOn(2)}>Inc</Button>
        <Button onClick={() => decrementOn(3)}>Dec</Button>
        <Button onClick={resetCounter}>Reset</Button>
      </div>
  )
```

### `withReducer()`

```js

withReducer<S, A>(
  stateName: string,
  dispatchName: string,
  reducer: (state: S, action: A) => S,
  initialState: S | (ownerProps: Object) => S
): HigherOrderComponent
```

和`withState()`类似,但是使用的是 reducer 函数.  reducer 函数接收一个 state,一个 action, 返回一个新的 state. 之后新的 state 被应用

### `branch()`

```js
branch(
  test: (props: Object) => boolean,
  left: HigherOrderComponent,
  right: ?HigherOrderComponent
): HigherOrderComponent
```

接收一个检测函数, 和两个高阶组件, test 函数接受 owner 的 props.如果返回的是 true, `left`高阶组件被应用到 basecomponent, 反之,`right` 高阶组件被应用的 base component . 如果没有提供`right` 高阶组件, 返回包装的组件

### `renderComponent()`

```js
renderComponent(
  Component: ReactClass | ReactFunctionalComponent | string
): HigherOrderComponent
```

接受一个组件, 返回高阶组件版本.

和其他的期待高阶组件的助手函数联合使用,例如`branch()`:


```js

// `isLoading()` is a function that returns whether or not the component
// is in a loading state
const spinnerWhileLoading = isLoading =>
  branch(
    isLoading,
    renderComponent(Spinner) // `Spinner` is a React component
  )

// Now use the `spinnerWhileLoading()` helper to add a loading spinner to any
// base component
const enhance = spinnerWhileLoading(
  props => !(props.title && props.author && props.content)
)
const Post = enhance(({ title, author, content }) =>
  <article>
    <h1>{title}</h1>
    <h2>By {author.name}</h2>
    <div>{content}</div>
  </article>
)
```


### `renderNothing()`

```js
renderNothing: HigherOrderComponent
```

总是渲染`null`的高阶组件

也是和其他期待高阶组件的助手函数一起工作

```js
// `hasNoData()` is a function that returns true if the component has
// no data
const hideIfNoData = hasNoData =>
  branch(
    hasNoData,
    renderNothing
  )

// Now use the `hideIfNoData()` helper to hide any base component
const enhance = hideIfNoData(
  props => !(props.title && props.author && props.content)
)
const Post = enhance(({ title, author, content }) =>
  <article>
    <h1>{title}</h1>
    <h2>By {author.name}</h2>
    <div>{content}</div>
  </article>
)
```


### `shouldUpdate()`

```js
shouldUpdate(
  test: (props: Object, nextProps: Object) => boolean
): HigherOrderComponent
```

高阶组件版本的 `shouldComponentUpdate()`,test 函数接受当前的props和下一个 props

### `pure()`

```js
pure: HigherOrderComponent
```

阻止组件更新,除非是 props 发生变化. 使用`shallowEquall()`检测变化. 

### `onlyUdateForKeys()`

```js

onlyUpdateForKeys(
  propKeys: Array<string>
): HigherOrderComponent
```

阻止组件更新,只有在对应的 props中给定key的部分发生变化时才能执行更新.  使用的是`shallowEqual()`检测变化

这个方法对于优化是最好的, 因为只关心特定的 props 部分. 

实例:

```js
/**
 * If the owner passes unnecessary props (say, an array of comments), it will
 * not lead to wasted render cycles.
 *
 * Goes well with destructuring because it's clear which props the component
 * actually cares about.
 */
const enhance = onlyUpdateForKeys(['title', 'content', 'author'])
const Post = enhance(({ title, content, author }) =>
  <article>
    <h1>{title}</h1>
    <h2>By {author.name}</h2>
    <div>{content}</div>
  </article>
)
```


### `onlyUpdateForPropTypes()`

工作方式和`onlyUpdateForKeys()`类似,只是 props keys 是从 base component 的`propTypes`中获取的,和`setPropTypes()`一起非常有用. 

如果base component 没有任何的`propTypes`,组件不会执行任何更新操作. 这可能不是想要的结果,所以会在终端打印警告信息

```js
import PropTypes from 'prop-types'; // You need to import prop-types. See https://facebook.github.io/react/docs/typechecking-with-proptypes.html

const enhance = compose(
  onlyUpdateForPropTypes,
  setPropTypes({
    title: PropTypes.string.isRequired,
    content: PropTypes.string.isRequired,
    author: PropTypes.object.isRequired
  })
)

const Post = enhance(({ title, content, author }) =>
  <article>
    <h1>{title}</h1>
    <h2>By {author.name}</h2>
    <div>{content}</div>
  </article>
)
```

### `withContext()`

```js
withContext(
  childContextTypes: Object,
  getChildContext: (props: Object) => Object
): HigherOrderComponent
```

为子组件提供上下文.


### `getContext()`

```
getContext(
  contextTypes: Object
): HigherOrderComponent
```

从上下文中获取值并以 props 的形式传递.

### `lifycycle()`

```js
lifecycle(
  spec: Object,
): HigherOrderComponent
```

这是高阶组件版本的`React.Component()`,支持除了`render()`之外的所有`Component` API, render()方式是默认实现的. 任何`lifecycle()`方法引起的 state改变, 会传递给包装组件

实例:

```js
const PostsList = ({ posts }) => (
  <ul>{posts.map(p => <li>{p.title}</li>)}</ul>
)

const PostsListWithData = lifecycle({
  componentDidMount() {
    fetchPosts().then(posts => {
      this.setState({ posts });
    })
  }
})(PostsList);
```

### `toClass()`

```js
toClass:HigherOrderComponent
```

接收一个函数组件,包装成一个类. 如果是已经是一个类,就直接返回了


## Sattic property helpers

这些方法不仅仅是要返回新的组件, 还改变了组建的属性


### `setStatic()`

```js
setStatic(
  key: string,
  value: any
): HigherOrderComponent
```

为 base component 赋予`propTypes` 属性

### `setDisplayName`

```js
setDisplayName(
  displayName: string
): HigherOrderComponent
```

赋予`displayName`属性

## Utilities

Recompose 包含一些额外的助手, 不是高阶组件,但是仍然非常有用

### `compose()`

```js
compose(...functions: Array<Function>): Function
```

把多个高阶组件组合成一个. 这个方法和 Redux 中的 `compose()`, lodash-fp的 `flowRight()`, Ramda 的`compose()`工作原理是类似的.


### `getDisplayName()`

```js
getDisplayName(
  component: ReactClass | ReactFunctionalComponent
): string
```

返回 React 组件的显示名

### `wrapDisplayName()`

```js
wrapDisplayName(
  component: ReactClass | ReactFunctionalComponent,
  wrapperName: string
): string
```

返回显示名包装的React 组件.   

### `shallowEqual()`

```js
shallowEqual(a:Object,b:Object):boolean
```

### `isClassComponent()`

```js
isClassComponent(value:any):boolean
```

### `createSink()`

```js
 createSink(callback:(props:Object)=>void):ReactClass
```

什么也渲染,仅仅调用回调函数

### `componentFromProp()`

```js
componentFromProp(propName: string): ReactFunctionalComponent
```

创建一个组件以 props的形式接收另一个组件, 并使用剩余的 props 渲染这个组件

```js
const enhance = defaultProps({ component: 'button' })
const Button = enhance(componentFromProp('component'))

<Button foo="bar" /> // renders <button foo="bar" />
<Button component="a" foo="bar" />  // renders <a foo="bar" />
<Button component={Link} foo="bar" />  // renders <Link foo="bar" />
```


### `nest()`

```js
nest(
  ...Components: Array<ReactClass | ReactFunctionalComponent | string>
): ReactClass
```

返回嵌套的组件

```js
// Given components A, B, and C
const ABC = nest(A, B, C)
<ABC pass="through">Child</ABC>

// Effectively the same as
<A pass="through">
  <B pass="through">
    <C pass="through">
      Child
    </C>
  </B>
</A>
```


### `hoistStatics()`

```js
hoistStatics(hoc: HigherOrderComponent): HigherOrderComponent
```



