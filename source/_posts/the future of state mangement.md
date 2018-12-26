---
title: 未来的状态管理技术
date: 2018-01-04 04:01:45
tags: [javacript,Apollo,Apollo-Client,app-link,app-link-state,GraphQL] 
---
![](https://cdn-images-1.medium.com/max/2000/1*YfE1f2lBr0hnpcRESiUy1w.png)
# 未来的状态管理技术 
`使用apollo-link-state在Apollo client管理本地状态**`
随着应用规模的增长，它的状态也日趋复杂化。作为一个开发者我们的任务不仅要从多个远程服务器获取五花八门的数据，同时还要处理与UI交互有关的本地数据。最糟糕的是，我们不得不考略怎么存储这些数据，以便于应用中的组件可以轻松访问数据。
很多的开发者的诉求是Apollo client在远程数据的管理上非常优秀，远程数据大概占据了他们80%的数据需求。但是本地数据(例如：全局标记，设备API反馈结果)怎么才能满足剩下的20%需求？
在以前(其实也不算久)，Apollo用户在独立的Redux或者Mobx store(两种数据构架存储数据的对象)中管理20%的本地数据需求。对于apollo client 1.0这么做是可行的解决办法，但是Apollo client 2.0已经完全从Redux构建中迁移出来，结果是在如果要在Apollo的store和本地管理构建的store之间同步本地，远程数据会变得非常棘手。最终用户的诉求是希望能在Apollo client中封装本地和远程数据，保持单一数据来源(**one source of truth**)。

### 依靠坚实的基础
Apollo开发者知道，必须要解决这个迫在眉睫的问题，所谓我们提出了问题：在Apollo client中管理状态到底应该是什么样子？刚开始，我们认为应该具有类似Redux的特征，例如Redux的dev tools以及通过connect函数把state注入到组件中。但是我们也考虑到了Redux自身的缺陷，例如模板的问题，还有DIY的问题，核心的特性，例如异步action creator(asyncchronous action creator,Redux执行异步操作时的action的函数一般都有三个)，缓存(caching),以及optimistic UI。

为了创建理想的state管理方案，我们想依据Redux构建，但是又避免它的备受批评的方面。同时还要使用GraphQL的强大的能力：也就是一次查询，从多个数据源返回数据。
![](https://cdn-images-1.medium.com/max/1600/1*ZHTs1iOH247NQLEOxXzHFw.png)

### 一次学习，到处编写GraphQL查询
对于GraphQL的一个常见误解是：它和特定的服务器实现耦合在一起。实际上，GraphQL非常灵活。不管你是从gRPC,REST或者客户端缓存查询数据都可以实现-GraphQL就是**数据通用查询语言**，操作与数据来源无关。
这就是GraphQL查询和突变(query,mutation)完美契合应用状态改变需求的原因。不再使用Redux的分发动作(dispatching action，Redux中触发状态改变的函数),我们使用GraphQL mutation来表现状态的改变。可以通过GraphQL的query来表明组件的数据需求，从而可以访问到相应的数据。
GraphQL的最大优点是它可以聚合来自多个数据来源的数据，不管是本地还是远程数据，只要在一个查询里通过指令(directive,graphQL里的语法，可以灵活的构建查询).定制需要的字段。 🎉好吧！来看看怎么实现

### 通过Apollo Client管理状态
在Apollo Ｃlient中管理本地数据通过[Apollo Link](https://www.apollographql.com/docs/link/)实现，Apollo Link是client中的网络技术栈，可以让你在任何地点接入到GraphQL的请求周期中。为了从GraphQL服务器请求远程数据，我们可以使用`HttpLink`,但是为了从缓存中请求本地数据，我们需要安装新的link:`apollo-link-state`。

```javascript
import { ApolloClient } from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { ApolloLink } from 'apollo-link';
import { withClientState } from 'apollo-link-state';
import { HttpLink } from 'apollo-link-http';

import { defaults, resolvers } from './resolvers/todos';

const cache = new InMemoryCache();

const stateLink = withClientState({ resolvers, cache, defaults });

const client = new ApolloClient({
  cache,
  link: ApolloLink.from([stateLink, new HttpLink()]),
});
```
使用apollo-link-state初始化Apollo Client
为了创建state link,可以使用`withClientState`函数，传递的具有`resolvers`,`defaults`和Apollo`cache`属性的对象。接着拼接本地sate link到整个link链中。state link应该在`HttpLink`之前出现，因此本地查询和突变到达网络成之前就会被拦截。

####默认配置(Defaults)
`defaults`对象代表着写入缓存时创建的state link的初始状态。在没有需求时，传递`defaults`对象给cache热个身是非常重要的，这样做组件在查询状态数据时才不会出错(译注：这里和Redux的reducer中返回默认的initailState是一个意思，可以返回空对象，但是不能undefined)。定义的`defaults`对象外观应该可以反映出在应用中计划实现的查询方案。

```javascript
export const defaults = {
  visibilityFilter: 'SHOW_ALL',
  todos: [],
};
```
默认对象代表着想读写cache的初始化状态

#### Resolvers(查询解析函数)
如果使用Apollo Client来管理state,Apollo cache就称为应用中所有远程数据和本地数据的单一来源。怎么访问和更新cache中的数据？resolvers应运而生。如果你在服务器端使用过`graph-tools`，client端的resolver类型签名与之相同：

```javascript
fieldName: (obj, args, context, info) => result;
```
如果不熟悉resolvers，也不用担心，这里要注意的两个重点是查询或者突变的变量在第二个参数中传递，cache会在context中自动添加(在服务端，需要在context中手动指定查询的配置，可以是rest地址，也可以是数据库配置)。

```javascript
export const defaults = { // same as before }
  
export const resolvers = {
  Mutation: {
    visibilityFilter: (_, { filter }, { cache }) => {
      cache.writeData({ data: { visibilityFilter: filter } });
      return null;
    },
    addTodo: (_, { text }, { cache }) => {
      const query = gql`
        query GetTodos {
          todos @client {
            id
            text
            completed
          }
        }
      `;
      const previous = cache.readQuery({ query });
      const newTodo = {
        id: nextTodoId++,
        text,
        completed: false,
        __typename: 'TodoItem',
      };
      const data = {
        todos: previous.todos.concat([newTodo]),
      };
      cache.writeData({ data });
      return newTodo;
    },
  }
}
```
Resolvers是访问和更新cache中数据的函数

为了把数据写到cache的根下，调用`cache.writeData`函数，并传递自己的数据。有时候，我们写入到cache的数据是和之前的数据有关的，例如上面实例中的mutation操作`addTodo`。在这种情况下，需要在执行写操作之前使用`cache.readQuery`函数从cache中读取之前的数据，如果你只是对cache中已经存在的对象写入部分数据，可以选择性传入一个`id`，这个`id`代表着相应对象在cache中的key.因为我们在apollo client store中使用的是`InMemoryCache`，key是`_.typename:id`.

#### @client directive(@client指令)
如果我们从UI中触发一个mutation.Apollo client需要知道这个动作到底是要更新服务器的数据，还是客户端本地数据。`apollo-link-state`使用`@client`指令来界定只能用于客户端数据的操作。接着`apollo-link-state`调用resolvser来处理相关字段。

```javascript
const SET_VISIBILITY = gql`
  mutation SetFilter($filter: String!) {
    visibilityFilter(filter: $filter) @client
  }
`;

const setVisibilityFilter = graphql(SET_VISIBILITY, {
  props: ({ mutate, ownProps }) => ({
    onClick: () => mutate({ variables: { filter: ownProps.filter } }),
  }),
});
```
通过@client指令针对本地数据执行mutation操作

query操作和mutation操作类似。如果你在查询中正在执行异步操作，Apollo Client将会为你跟踪loading和error状态。对React而言，你可以在`this.props.data`中找到这些状态，其中还包括很多的助手函数，包括refetching(刷新)，pagination(分页)和polling(轮询)。

最令人心动的特性是你可以在一次查询中从多个数据源请求数据！😍 
在这个例子中，我们可以从GraphQL服务器远程请求`user`信息，同时从Apollo cache中请求本地的`visiblityFilter`数据。

```javascript
const GET_USERS_ACTIVE_TODOS = gql`
  {
    visibilityFilter @client
    user(id: 1) {
      name
      address
    }
  }
`;

const withActiveState = graphql(GET_USERS_ACTIVE_TODOS, {
  props: ({ ownProps, data }) => ({
    active: ownProps.filter === data.visibilityFilter,
    data,
  }),
});
```
通过@client指令请求本地数据，user没有@client指令，是远程请求数据。更多有关在应用中整合`apollo-link-state`的示例和技巧，请关注我们的[文档更新页面](https://www.apollographql.com/docs/link/links/state.html)

### 到1.0版本的技术路线
现在，尽管`apollo-link-state`已经足够稳定，可以在应用使用了，但是还有几个特性，我们很快会解决：

*  **Client-side schema(客户端图式)**：现在，客户端还不支持根据客户端schema所做的类型验证。这是因为在运行时包含用于构建和验证schema会显著的增加打包文件的大小。替换方案是，我们希望把schema构建转移到构建阶段，通过对GraphQL内省(introspection)的支持，你可以获取GraphiQL中所有很酷的特征。
*  **Helper组件**：我们的目标是尽可能的使apollo中的状态管理无差别。我们编写一些React组件，从而减少执行普通任务时的多余代码，例如在执行mutation时，在幕后传递参数，需用考虑细节配置。

如果你你对这些问题感兴趣，可以加入[github](https://github.com/apollographql/apollo-link-state) 或者是 Apollo Slack的`#local-state`频道。我们很感激你可以帮助塑造下一代的状态管理方案！🚀


`React`,`GraphQL`,`JavaScript`,`Redux`,`API`






