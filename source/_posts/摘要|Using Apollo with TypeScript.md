---
title: 摘要|Using Apollo with TypeScript
date: 2018-03-16 10:40:34
categories: 技术备忘
tags: [GraphQL,Apollo]
---

### typescript 需要额外定义类型

```js
import React from "react";
import gql from "graphql-tag";
import { graphql } from "react-apollo";

const HERO_QUERY = gql`
  query GetCharacter($episode: Episode!) {
    hero(episode: $episode) {
      name
      id
      friends {
        name
        id
        appearsIn
      }
    }
  }
`;
//类型
type Hero = {
  name: string;
  id: string;
  appearsIn: string[];
  friends: Hero[];
};
//查询结果的类型
type Response = {
  hero: Hero;
};

const withCharacter = graphql<Response>(HERO_QUERY, {
  options: () => ({
    variables: { episode: "JEDI" }
  })
});

export default withCharacter(({ data: { loading, hero, error } }) => {
  if (loading) return <div>Loading</div>;
  if (error) return <h1>ERROR</h1>;
  return ...// actual component with data;
});
```

### 对于查询参数也需要定义类型

```js
type InputProps = {
  episode: string
};

const withCharacter = graphql<Response, InputProps>(HERO_QUERY, {
  options: ({ episode }) => ({
    variables: { episode }
  }),
});
```

### 在包装组件获取 props 时也需要定义

```js
import React from "react";
import gql from "graphql-tag";
import { graphql, NamedProps, QueryProps} from "react-apollo";

const HERO_QUERY = gql`
  query GetCharacter($episode: Episode!) {
    hero(episode: $episode) {
      name
      id
      friends {
        name
        id
        appearsIn
      }
    }
  }
`;

type Hero = {
  name: string;
  id: string;
  appearsIn: string[];
  friends: Hero[];
};

type Response = {
  hero: Hero;
};

type WrappedProps = Response & QueryProps;

type InputProps = {
  episode: string
};

const withCharacter = graphql<Response, InputProps, WrappedProps>(HERO_QUERY, {
  options: ({ episode }) => ({
    variables: { episode }
  }),
  props: ({ data }) => ({ ...data })
});

export default withCharacter(({ loading, hero, error }) => {
  if (loading) return <div>Loading</div>;
  if (error) return <h1>ERROR</h1>;
  return ...// actual component with data;
});
```

### 使用class组件定义


```js
import { ChildProps } from "react-apollo";

const withCharacter = graphql<Response, InputProps>(HERO_QUERY, {
  options: ({ episode }) => ({
    variables: { episode }
  })
});

class Character extends React.Component<ChildProps<InputProps, Response>, {}> {
  render(){
    const { loading, hero, error } = this.props.data;
    if (loading) return <div>Loading</div>;
    if (error) return <h1>ERROR</h1>;
    return ...// actual component with data;
  }
}

export default withCharacter(Character);
``` 


