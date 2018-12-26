---
title: Apollo|API Reference
date: 2018-03-06 09:51:39
categories: 技术备忘
tags: [GraphQL,Apollo-Client]
---
{{TOC}}
##   `ApolloClient`

- `link`
- `cache`
- `ssrMode`
- `ssForceFetchDelay`
- `connectToDevTools`
- `queryDeduplication`
- `defaultOptions`

```js
const defaultOptions = {
  watchQuery: {
    fetchPolicy: 'cache-and-network',
    errorPolicy: 'ignore',
  },
  query: {
    fetchPolicy: 'network-only',
    errorPolicy: 'all',
  },
  mutate: {
    errorPolicy: 'all'
  }
}
```

### `ApolloProvider`

为所有的组件提供一个`ApolloClient`实例
- client

```js
ReactDOM.render(
  <ApolloProvider client={client}>
    <MyRootComponent />
  </ApolloProvider>,
  document.getElementById('root'),
);
```

### `graphql(query,[config])(Component)`

```js
function TodoApp({ data: { todos } }) {
  return (
    <ul>
      {todos.map(({ id, text }) => (
        <li key={id}>{text}</li>
      ))}
    </ul>
  );
}

export default graphql(gql`
  query TodoAppQuery {
    todos {
      id
      text
    }
  }
`)(TodoApp);
```

可以定义中间函数

```js
// Create our enhancer function.
const withTodoAppQuery = graphql(gql`query { ... }`);

// Enhance our component.
const TodoAppWithData = withTodoAppQuery(TodoApp);

// Export the enhanced component.
export default TodoAppWithData;
```


## Query Configuration


### `config.options`

```js
export default graphql(gql`{ ... }`, {
  options: (props) => ({
    // Options are computed from `props` here.
  }),
})(MyComponent);
```

### `config.props`

```js
export default graphql(gql`{ ... }`, {
  props: ({ data: { fetchMore } }) => ({
    onLoadMore: () => {
      fetchMore({ ... });
    },
  }),
})(MyComponent);

function MyComponent({ onLoadMore }) {
  return (
    <button onClick={onLoadMore}>
      Load More!
    </button>
  );
}
```


### `config.skip`

不会执行其中的React Apollo 功能
可以传递布尔值,也是传递函数给`config.skip`,
这里连个查询根据 props.userQuery1的属性来判断实现那个查询, 注意 true 时跳过查询
```
export default compose(
  graphql(gql`query MyQuery1 { ... }`, { skip: props => !props.useQuery1 }),
  graphql(gql`query MyQuery2 { ... }`, { skip: props => props.useQuery1 }),
)(MyComponent);

function MyComponent({ data }) {
  // The data may be from `MyQuery1` or `MyQuery2` depending on the value
  // of the prop `useQuery1`.
  console.log(data);
}
```

### `config.name`

`name` 配置传递给组件 props的名字. 默认是query用 `data`. mutation用`mutate`. 

```js
//⛔️注入多个函数时用 compose函数
export default compose(
  graphql(gql`mutation (...) { ... }`, { name: 'createTodo' }),
  graphql(gql`mutation (...) { ... }`, { name: 'updateTodo' }),
  graphql(gql`mutation (...) { ... }`, { name: 'deleteTodo' }),
)(MyComponent);

function MyComponent(props) {
  // Instead of the default prop name, `mutate`,
  // we have three different prop names.
  console.log(props.createTodo);
  console.log(props.updateTodo);
  console.log(props.deleteTodo);

  return null;
}
```

### `config.withRef`

这个存在时什么意义呢?

### `config.alias`

### `compose(...enhancers)(component)`

借此可以一次使用多个组件增强子. compose(funcC,funcB,funcA)(component),  实际的执行方式为  funcC(funcB(funcA(component)))

```
export default compose(
  withApollo,
  graphql(`query { ... }`),
  graphql(`mutation { ... }`),
  connect(...),
)(MyComponent);
```

### `withApollo(component)`

```js
export default withApollo(MyComponent);

function MyComponent({ client }) {
  console.log(client);
}
```
使用 `withApollo`可以在组件中直接访问到Client 实例

