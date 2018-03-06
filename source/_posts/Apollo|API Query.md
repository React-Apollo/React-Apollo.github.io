---
title: Apollo|Query
date: 2018-03-06 12:28:41
categories: 技术备忘
tags: [GraphQL,Apollo-Client]
---
{{TOC}}
#  Query 
核心的理念是这也就是"GraphQL",并没有什么新内容. 

## 基础查询

简单的使用`graphql` container. 解析查询使用的`gql`模板字符串,并传递给`graphql`container.作为第一个参数.

实例 : 在['GitHunt'](https://github.com/apollographql/Githunt-React)中,我们会在`Profile`组件显示当前登录的用户

``` js
import React, { Component } from 'react';
import { graphql } from 'react-apollo';
import gql from 'graphql-tag';

class Profile extends Component { ... }

// We use the gql tag to parse our query string into a query document
const CurrentUserForLayout = gql`
  query CurrentUserForLayout {
    currentUser {
      login
      avatar_url
    }
  }
`;

const ProfileWithData = graphql(CurrentUserForLayout)(Profile);

```
在我们使用`graphql`时, 会发生两件事:
1. 查询从 Apollo-client的 data store 加载,如果不在 data store 中就从 server 加载
2. 我们的组件订阅到 store. 所以如果数据发生改变, 组件就会更新

此外,对于在 query中的`currentUser`字段,`data`属性也包含有字段`loading`,这是一个布尔值, 表示当前从 server 加载数据的状态. 还有一个字段`error`,表示是否在加载数据时出现错误.  所以具体的属性的外观如下:

```js
(props) => {
    const loading = props.data.loading;
    const error = props.data.error;
    const currentUser = props.data.currentUser;
    // render UI with loading, error, or currentUser
}
```

`data.currentUser`属性会随着用户的变化而发生变化. 信息存储在 Apollo client 的 全局 cache 中.


### `data`属性的结构

如上所示, `graphql`会传递查询结果到被包装的组件,形式是`data`属性. 实际也传递所有的父组件的 props.

对于查询, `data`属性的外观如下

- `...fileds`: 查询中的每个根字段
- `loading`: 如果有查询进行中, 这个字段为`true`,包含`refetch`查询时也是如此
- `error`: APolloError对象代表查询中可能出现的各种错误.

 例如下面的查询:
 
```js
 query getUserAndLikes($id: ID!) {
  user(userId: $id) { name }
  likes(userId: $id) { count }
}
```
 
 我们得到的 props 如下:
 
```js
 data: {
  user: { name: "James" },
  likes: { count: 10 },
  loading: false,
  error: null,
  variables: { id: 'asdf' },
  refetch() { ... },
  fetchMore() { ... },
  startPolling() { ... },
  stopPolling() { ... },
  // ... more methods
}
```

### Variables 和 options

如果想定制query,可以提供 option选项,作为`graphql`的第二个参数(第一个参数为查询字符串).如果需要传递变量,要在这个地方传递

```js
// Suppose our profile query took an avatar size

const CurrentUserForLayout = gql`
  query CurrentUserForLayout($avatarSize: Int!) {
    currentUser {
      login
      avatar_url(avatarSize: $avatarSize)
    }
  }
`;

const ProfileWithData = graphql(CurrentUserForLayout, {
  options: { variables: { avatarSize: 100 } },
})(Profile);
``` 

`这里可能会有疑问, 一般在获取当前用户的时候需要传递 token,在 apollo client 中,我们在配置url 时,在头部从本地数据库获得到用户token,然后传递`.


## 从 props 进行计算

典型应用中,查询的变量或从包装组件的 props 中计算. 无论在什么地方使用组件,调用都会传递参数,所以`options`可以作为函数接受传递给组件的 props

```js
// The caller could do something like:
<ProfileWithData avatarSize={300} />

// And our HOC could look like:
const ProfileWithData = graphql(CurrentUserForLayout, {
  options: ({ avatarSize }) => ({ variables: { avatarSize } }),
})(Profile);
```

默认情况下, `graphql`会尝试从`ownPorps`中获取需要的变量
## 其他的 options

可以传递其他的 options,例如`pollInterval`

```js
const ProfileWithData = graphql(CurrentUserForLayout, {
  // See the watchQuery API for the options you can provide here
  options: { pollInterval: 20000 },
})(Profile);
```

### skipping an operation
//如果认证没有通过就跳过这个查询,可以直接设为静态的 skip:true
```js
const ProfileWithData = graphql(CurrentUserForLayout, {
  skip: (ownProps) => !ownProps.authenticated,
})(Profile);
```

### 改变 prop的名字

```js
import React, { Component } from 'react';
import { graphql } from 'react-apollo';
import gql from 'graphql-tag';

class Profile extends Component { ... }

const CurrentUserForLayout = gql`
  query CurrentUserForLayout {
    currentUser {
      login
      avatar_url
    }
  }
`;

// We want the prop to be called 'CurrentUserForLayout' instead of data
const ProfileWithData = graphql(CurrentUserForLayout, {
  name: 'CurrentUserForLayout'
})(Profile);
```

### 任意的转换

想完全控制传递给子组件的 props,可以使用`props` option 把 query 的`data`  映射为任意数量的 props

```js
import React, { Component } from 'react';
import { graphql } from 'react-apollo';
import gql from 'graphql-tag';

// Here Profile has a more generic API, that's not coupled to Apollo or the
// shape of the query that we've used
class Profile extends Component { ... }

const CurrentUserForLayout = gql`
  query CurrentUserForLayout {
    currentUser {
      login
      avatar_url
    }
  }
`;

const ProfileWithData = graphql(CurrentUserForLayout, {
  // ownProps are the props that are passed into the `ProfileWithData`
  // when it is used by a parent component
  props: ({ ownProps, data: { loading, currentUser, refetch } }) => ({
    userLoading: loading,
    user: currentUser,
    refetchUser: refetch,
  }),
})(Profile);
```

这个方式最大限度的解耦了展示组件(Profile)和 Apollo

## API  Reference 

```js
render() {
  const { data } = this.props; // <- The `data` prop.
}
```

如果我们要下面的查询

```js
{
   viwer{name}
   todos{text}
}
```

你的`data` props 将会包含如下数据

```js
render() {
  const { data } = this.props;

  console.log(data.viewer); // <- The data returned by your query for `viewer`.
  console.log(data.todos); // <- The data returned by your query for `todos`.
}
```


### `data.networkStatud`

- `loading`
- `setVariables`: query 的变量改变
- `fetchMore`: 表示`fetchMore`在调用
- `refetch`: refetch 在调用
- `poll`: polling 在调用
- `ready`: 没有操作进行中
- `error`: 没有请求, 但是至少有一个错误

如果 network status 小于7 等同于`data.loading`==true

实例

```js
function MyComponent({ data: { networkStatus } }) {
  if (networkStatus === 6) {
    return <div>Polling!</div>;
  } else if (networkStatus < 7) {
    return <div>Loading...</div>;
  } else {
    // ...
  }
}

export default graphql(gql`query { ... }`)(MyComponent);
```

### `data.variables`

Apollo 用于获取数据的参数, 如果你想渲染一些与参数有关的信息

```js
function MyComponent({ data: { variables } }) {
  return (
    <div>
      Query executed with the following variables:
      <code>{JSON.stringify(variables)}</code>
    </div>
  );
}

export default graphql(gql`query { ... }`)(MyComponent);
```

### `data.refetch(variables)`
 
 强制你的组件重新执行在`graphql()`函数中定义的操作. 当你想重载数据,或者是遇到错误时再次获取数据
 
 `data.refetch`返回一个promise,resolves返回新的数据. 

### `data.fetchMore(options)`

`data.fetchMore`函数可以实现组件的分页操作. 接收单个`options`对象作为参数,有下面的属性:
- `[query]`:可选项,如果不使用就从`graphql()` hoc采用
- `[variables]`: 可选的参数, 和上面一样的用法
- `updateQuery(previousResult,{fetchMoreResult,queryVariables})`:实际执行分页时的函数. 第一个参数`previousResult`,是之前的查询返回的数据, 第二个参数有两个属性,`fetchMoreResult`,`queryVariables`,`fetchMoreResult`是新查询返回的数据, `queryVariables`是获取更多数据时采用的参数.使用这些参数,你应该返回一个新的`data`,和之前的data的外观一致. 参看下面的的实例

```js
data.fetchMore({
  updateQuery: (previousResult, { fetchMoreResult, queryVariables }) => {
    return {
      ...previousResult,
      // Add the new feed data to the end of the old feed data.
      //在旧的数据末尾拼接新的数据
      feed: [...previousResult.feed, ...fetchMoreResult.feed],
    };
  },
});
```

### `data.subscribeToMore(options)`

这个函数会配置 subscrption,当 server 发布subscription时,触发更新.需要在 server 做相应的工作. 
还会返回一个`unscribe()`函数,可以用于解绑定

通常的实践是在`componentWillReceiveProps`内包装`subscribeToMore`调用,在原始的查询完成之后,执行订阅. 为了确保不会多次创建 subscription.可以添加到组件实例上.

- `[document]`:  graphql 的查询字符串
- `[variables]`: 可选的参数, 可以用在`document`option 中
- `[updataQuery]`: 可选的函数, server 发送更新时时会执行. 第一个参数`previousResult`是之前的查询结果,第二个参数是一个对象,有两个属性,`subscriptionData`是订阅的结果. `variables`是用于订阅的参数
- `[onError]`: 可选的出现错误的回调函数

```
class SubscriptionComponent extends Component {
  componentWillReceiveProps(nextProps) {
    if(!nextProps.data.loading) {
      // Check for existing subscription
      if (this.unsubscribe) {
        // Check if props have changed and, if necessary, stop the subscription
        if (this.props.subscriptionParam !== nextProps.subscriptionParam) {
          this.unsubscribe();
        } else {
          return;
        }
      }

      // Subscribe
      this.unsubscribe = nextProps.data.subscribeToMore({
        document: gql`subscription {...}`,
        updateQuery: (previousResult, { subscriptionData, variables }) => {
          // Perform updates on previousResult with subscriptionData
          return updatedResult;
        }
      });
    }
  }
  render() {
    ...
  }
}
 
```

### `data.startPolling(interval)`
这个函数设置一个间隔, 间隔时间完了以后会发送一个 fetch请求. 直接收一个整数参数. Polling 是保持 UI中数据随时更新的好方法. 通过设置每5秒中重新获取数据. 可以有效的模拟实现实时数据更新, 后台不需要做任何的构建工作

```js
class MyComponent extends Component {
  componentDidMount() {
    // In this specific case you may want to use `options.pollInterval` instead.
    this.props.data.startPolling(1000);
  }

  render() {
    // ...
  }
}

export default graphql(gql`query { ... }`)(MyComponent);
```

### `data.stopPolling()`
通过调用这个函数,可以停止当前的 polling 过程.

```js
class MyComponent extends Component {
  render() {
    return (
      <div>
        <button onClick={() => {
          this.props.data.startPolling(1000);
        }}>
          Start Polling
        </button>
        <button onClick={() => {
          this.props.data.stopPolling();
        }}>
          Stop Polling
        </button>
      </div>
    )
  }
}

export default graphql(gql`query { ... }`)(MyComponent);
``` 


### `data.updataQuery(updaterFn)`

在 query 和 mutate 之外对 data做出改变

```
data.updateQuery((previousResult) => ({
  ...previousResult,
  count: previousResult.count + 1,
}));
```


### `config.options`

用于配置查询和更新的对象或者函数
如果`config.options`是一个函数,就可以接受一个组件的 props 作为第一个参数.

```js
export default graphql(gql`{ ... }`, {
  options: {
    // Options go here.
  },
})(MyComponent);
```

```js
export default graphql(gql`{ ... }`, {
  options: (props) => ({
    // Options are computed from `props` here.
  }),
})(MyComponent);
```

### `options.variables`

用于执行查询的变量. 这些变量应该和查询中定义的变量一一对应. 如果`config.options`作为函数,就可以从props 中计算变量

实例:
```js
export default graphql(gql`
  query ($width: Int!, $height: Int!) {
    ...
  }
`, {
  options: (props) => ({
    variables: {
      width: props.size,
      height: props.size,
    },
  }),
})(MyComponent);

```

### `optins.fetchPolicy`
fetchPolicy 是可选项,可以定制组件和 Apollo data cache 交互的方法. 默认情况下, 组件首先尝试从 cache获取数据. 如果需要的所有数据都在 cache 中, Apoll 会直接从 cache 中返回数据. 

有效的`fetchPolicy`如下:

- `cache-first`: 默认的选项
- `cache-and-network` : 如果 cache 中有全部数据, 就会直接返回,但是网络获取也会执行, 从而保持了 server 和 cache 的数据一致性. 不仅使用户迅速获得数据,还保持数据的一致性
- `network-only`: 不从 cache 中返回数据
- `cache-only`: 不执行网络获取


```js
export default graphql(gql`query { ... }`, {
  options: { fetchPolicy: 'cache-and-network' },
})(MyComponent);
```


### `options.errorPolicy`
用于定制 fetch data error的处理. runtime error和获取数据错误

- `none`: 默认值,
- `ignore`: 
- `all`: 

### `options.pollInterval`

```js
export default graphql(gql`query { ... }`, {
  options: { pollInterval: 5000 },
})(MyComponent);
```

### `options.notifyOnNetworkStatusChange`

网络状态发生变化时,触发组件的重新渲染

实例:
```
export default graphql(gql`query { ... }`, {
  options: { notifyOnNetworkStatusChange: true },
})(MyComponent);
```

### `optins.context`

在`context`对象下的所有的内容都可以直接传递到 network chain 中. 













