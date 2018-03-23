---
title: Apollo|apollo-link-state local state management
date: 2018年3月23日下午3:30:10
categories: 技术备忘
tags: [GraphQL,Redux,Apollo]
---
> Apollo-client中的本地数据管理方法. 和远程数据的流动方向一样, 但是在到达 server之前会被 apollo-link-state 截获,并做处理.数据仍然保持单向流动. 


调用`withClientState`方法,并使用 resolver做对应的处理. 

```js
import { withClientState } from 'apollo-link-state';

// This is the same cache you pass into new ApolloClient
const cache = new InMemoryCache(...);

const stateLink = withClientState({
  cache,
  resolvers: {
    Mutation: {
      updateNetworkStatus: (_, { isConnected }, { cache }) => {
        const data = {
          networkStatus: {
            __typename: 'NetworkStatus',
            isConnected
          },
        };
        cache.writeData({ data });
        return null;
      },
    },
  }
});
```

在 Apollo-client 上挂载 state,state link 应该在在链的末端,由此其他的 link 可以做逻辑上的处理, 但是`必须要在 HttpLink之前`,只有这样本地的操作才可以在到达网络之前被截获.  如果使用了持久化查询(persisted queries), 也必须要在`apollo-link-persisted-queries`之前.  

```js
const client = new ApolloClient({
  cache,
  link: ApolloLink.from([stateLink, new HttpLink()]),
});
```


请求远程数据和本地数据,通过`@client`指令来区分. 


```js
const UPDATE_NETWORK_STATUS = gql`
  mutation updateNetworkStatus($isConnected: Boolean) {
    updateNetworkStatus(isConnected: $isConnected) @client
  }
`;
```


在组件注入 query 或者 mutate 就可以了

```
const WrappedComponent = graphql(UPDATE_NETWORK_STATUS, {
  props: ({ mutate }) => ({
    updateNetworkStatus: isConnected => mutate({ variables: { isConnected } }),
  }),
})(NetworkStatus);
```

如果要从其他组件访问 nework status 怎么办? 因为在访问之前,并不知道是否有`UPDATA_NETWORK_STATUS`存在,为了防止出现 undefined,需要提供一个默认的 state 作为初始值.

```js
const stateLink = withClientState({
  cache,
  resolvers: {
    Mutation: {
      /* same as above */
    },
  },
  defaults: {
    networkStatus: {
      __typename: 'NetworkStatus',
      isConnected: true,
    },
  },
});
```


组件查询 network也使用`@client`指令

```js
const GET_ARTICLES = gql`
  query {
    networkStatus @client {
      isConnected
    }
    articles {
      id
      title
    }
  }
`;
```

---
## Defaults

```js
const defaults = {
  todos: [],
  visibilityFilter: 'SHOW_ALL',
  networkStatus: {
    __typename: 'NetworkStatus',
    isConnected: false,
  }
};

const resolvers = { /* ... */ };

const cache = new InMemoryCache();

const stateLink = withClientState({
  resolvers,
  cache,
  defaults
});
```

## Resolvers

resolvers 是实现 local state 的地方.  resolver的 map是对应每个 GraphQL 对象类型的resolver 函数.  

`apollo-link-state`有四个重要的部分

1. cache在上下文中,可以用来读取数据
2. resolver 应该返回一个有`_typename`属性的对象, 也可以用`dataIdFromObject`代替.  目的是 Apollo 用于数据的normalize
3. 如果需要执行异步操作,可以使用 promise.
4. Query只针对 cache. 如果在所有的 mutate 之前执行 query,需要提供默认值

## Default resolvers

不一定要为每个字段都建立特定的 resolvers,如果从 parent 对象返回的值和children 请求的字段一致,就不需要 resolvers.这就是`default resovlers`

```js

const getUser = gql`
  query {
    user(id: 1) @client {
      name {
        last
        first
      }
    }
  }
`;
```

## Resolvers signature

Apollo-client 中的resolver 函数和用`graph-tools`构建的 server 中的 resolvers 是完全一样的.  

```js
fieldName:(obj,args,context,info)=>result;
```

1. `obj`: 包含 parent 字段 或者`ROOT_QUERY`对象
2. `args`: 传递进入的参数, 例如`updataNetworkStatus(isConnected:true)`,`args`对象就是`{isConnected:true}`
3. `context`: 在所有的link 中共享的数据. 重要的的一点是Apollo cache添加在其中,所以可以用`cache.writeData({})`.如果想设定额外的值,可以在组件内设定,或者使用`apollo-link-context`. 
4. `info`:  有关 state 执行状态的信息. 个人不会用到


##  Async resolvers

如果想访问 REST 数据,可以参考`apollo-link-rest`.  

对于 RN或者 其他的 browser API,需要在组件的生命周期方法中添加触发函数.
这一部分暂时不写
----

## Organizing resolvers

使用鸭子类型 ,每个feature都有自己的一套方法,然后合并起来

```js
import merge from 'lodash.merge';
import { withClientState } from 'apollo-link-state';

import currentUser from './resolvers/user';
import cameraRoll from './resolvers/camera';
import networkStatus from './resolvers/camera';

const stateLink = withClientState({
  cache,
  resolvers: merge(currentUser, cameraRoll, networkStatus),
});
```

可以设定默认值

```js
const currentUser = {
  defaults: {
    currentUser: null,
  },
  resolvers: { ... }
};

const cameraRoll = { defaults: { ... }, resolvers: { ... }};

const stateLink = withClientState({
  ...merge(currentUser, cameraRoll, networkStatus),
  cache,
});
```

## updating the cache

可以通过`context`访问或者更新 cache. Apollo cache API 有几个方法 

### writeData
直接在 Cahce 中写入数据,不用通过 query. 

```js
const filter = {
  Mutation: {
    updateVisibilityFilter: (_, { visibilityFilter }, { cache }) => {
      const data = { visibilityFilter, __typename: 'Filter' };
      cache.writeData({ data });
    },
  },
};
```

`如果传递id属性,也可以在已经存在的对象中写入片段数据.`

这里的`id`应该对应对象的 cache key. 如果使用`InMemroyCache`,并且没有覆盖`dataObjectFromId`,cache key就是`_typename:id`


```js
const user = {
  Mutation: {
    updateUserEmail: (_, { id, email }, { cache }) => {
      const data = { email };
      cache.writeData({ id: `User:${id}`, data });
    },
  },
};

```

## writeQuery 和 readQuery

在某些情况下,写入到 cache 的数据依赖于已经存在的数据,例如 ,在 list 中添加一条 item或者对属性做修改.  做法是使用`cache.readQuery`传递 query,在写入数据之前从 cache 中读取数据. 看看 list的例子

```js
let nextTodoId = 0;

const todos = {
  defaults: {
    todos: [],
  },
  resolvers: {
    Mutation: {
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
        const newTodo = { id: nextTodoId++, text, completed: false, __typename: 'TodoItem' },
        const data = {
          todos: previous.todos.concat([newTodo]),
        };

        // you can also do cache.writeData({ data }) here if you prefer
        cache.writeQuery({ query, data });
        return newTodo;
      },
    },
  },
};
```

为了在 list 中添加 todo, 需要当前的 todos, 可以通过`cache.readQuery`获取. 

为了写入数据到 cache.可以使用`cache.writeQuery`,`cache.writeData`. 不同点在于`cache.writeQuery`需要传递 query,来验证 data的结构.  在底层,`cache.write`自动从`data`构建了 query.  

## writeFragment 和 readFragment

`cache.writeFragment`,在有了 cache key 情况下, 可以灵活的读取数据.

```js
const todos = {
  resolvers: {
    Mutation: {
      toggleTodo: (_, variables, { cache }) => {
        const id = `TodoItem:${variables.id}`;
        const fragment = gql`
          fragment completeTodo on TodoItem {
            completed
          }
        `;
        const todo = cache.readFragment({ fragment, id });
        const data = { ...todo, completed: !todo.completed };

        // you can also do cache.writeData({ data, id }) here if you prefer
        cache.writeFragment({ fragment, id, data });
        return null;
      },
    },
  },
};
```

## @client directive

## Combining local and remote data

下面的例子中,我们从 server 获取到 username,从 apollo cache 获取到 cart 信息.两者在结果中融合在一起

```js
const getUser = gql`
  query getUser($id: String) {
    user(id: $id) {
      id
      name
      cart @client {
        product {
          name
          id
        }
      }
    }
  }
`;
```








