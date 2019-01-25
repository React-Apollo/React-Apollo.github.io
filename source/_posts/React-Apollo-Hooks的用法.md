---
title: React-Apollo-Hooks的用法
date: 2019年1月25日 7:40
categories: 技术备忘
tags: [Apollo,React]
---

<script src="https://cdn.bootcss.com/mathjax/2.7.5/latest.js"></script>
{{TOC}}

 # React-Apollo-Hooks的用法

## Introduction
> react-hooks的诞生彻底把React的组件函数化。 基本的思想延续了recompose的技术，对于组件的状态管理更为方便和直观了，所以立刻出现了很多的应用。 很多程序用react-hooks来写变得很直观，简洁。
> react-apollo-hooks的用法就在apollo查询组件的基础上更加方便使用了
## 初始化

```bash
npm install react-apollo-hooks
```

‌容器包装顶层组件

```jsx
import React from 'react';
import { render } from 'react-dom';

import { ApolloProvider } from 'react-apollo';
import { ApolloProvider as ApolloHooksProvider } from 'react-apollo-hooks';

const client = ... // create Apollo client

const App = () => (
  <ApolloProvider client={client}>
    <ApolloHooksProvider client={client}>
      <MyRootComponent />
   </ApolloHooksProvider>
  </ApolloProvider>
);

render(<App />, document.getElementById('root'));
```


## 具体使用

### 查询组件用法

```jsx
import gql from 'graphql-tag';
import { useQuery } from 'react-apollo-hooks';

const GET_DOGS = gql`
  {
    dogs {
      id
      breed
    }
  }
`;

const Dogs = () => {
  const { data, error } = useQuery(GET_DOGS);
  if (error) return `Error! ${error.message}`;

  return (
    <ul>
      {data.dogs.map(dog => (
        <li key={dog.id}>{dog.breed}</li>
      ))}
    </ul>
  );
};
```

####  可以结合suspense使用

```jsx
import React, { Suspense } from 'react';

const MyComponent = () => (
  <Suspense fallback={<div>Loading...</div>}>
    <Dogs />
  </Suspense>
);
```


#### apollo自身的状态表示

由于apollo自身已经对`网络层状态`(是网络硬件层的网络信息)信息进行了封装，组件中可以直接使用这些信息

```jsx
import gql from 'graphql-tag';
import { useQuery } from 'react-apollo-hooks';

const GET_DOGS = gql`...`;

const Dogs = () => {
  const { data, error, loading } = useQuery(GET_DOGS, { suspend: false });
  if (loading) return <div>Loading...</div>;
  if (error) return `Error! ${error.message}`;

  return (
    <ul>
      {data.dogs.map(dog => (
        <li key={dog.id}>{dog.breed}</li>
      ))}
    </ul>
  );
};
```

### Mutation的使用

```jsx
import gql from 'graphql-tag';
import { useMutation } from 'react-apollo-hooks';

const TOGGLE_LIKED_PHOTO = gql`
  mutation toggleLikedPhoto($id: String!) {
    toggleLikedPhoto(id: $id) @client
    //@client是apollo-link-state在本地的状态
  }
`;

const DogWithLikes = ({ url, imageId, isLiked }) => {
  const toggleLike = useMutation(TOGGLE_LIKED_PHOTO, {
    variables: { id: imageId },
  });
  return (
    <div>
      <img src={url} />
      <button onClick={toggleLike}>{isLiked ? 'Stop liking' : 'like'}</button>
    </div>
  );
};
```
### 服务端渲染

```jsx
import express from 'express';
import { ApolloProvider, getMarkupFromTree } from 'react-apollo-hooks';
import { renderToString } from 'react-dom/server';

const HELLO_QUERY = gql`
  query HelloQuery {
    hello
  }
`;

function Hello() {
  const { data } = useQuery(HELLO_QUERY);

  return <p>{data.message}</p>;
}

const app = express();

app.get('/', async (req, res) => {
  const client = createYourApolloClient();
  const renderedHtml = await getMarkupFromTree({
    renderFunction: renderToString,
    tree: (
      <ApolloProvider client={client}>
        <Hello />
      </ApolloProvider>
    ),
  });
  res.send(renderedHtml);
});
```


## Conclusion
React-Hooks让React技术更加简洁，明了。 

