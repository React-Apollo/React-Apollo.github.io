---
title: Apollo| Stateless Links
date: 2018-03-22 10:37:32
categories: 技术备忘
tags: [GraphQL,Apollo]
---
# Stateless Links

有些Link在每次请求中做的工作相同, 不需要知道具体的操作是什么. 这样的 Link 被称为 stateless Link. 不会在 link 之间共享 state. 对应的是 stateful Link

Stateless Links 可以作为包装`ApolloLink`接口的简单函数. 例如:

```js
import { ApolloLink } from 'apollo-link';

const consoleLink = new ApolloLink((operation, forward) => {
  console.log(`starting request for ${operation.operationName}`);
  return forward(operation).map((data) => {
    console.log(`ending request for ${operation.operationName}`);
    return data;
  })
})
```
statelss link 可以作为 middleware. 给 apollo-link-http 添加请求头是非常简单的一件事:

```js
import { ApolloLink } from 'apollo-link';

const authLink = new ApolloLink((operation, forward) => {
  operation.setContext(({ headers }) => ({ headers: {
    authorization: Meteor.userId() // however you get your token
  }}));
  return forward(operation);
});
```

可以定制操作函数例如:

```js
import { ApolloLink } from 'apollo-link';

const reportErrors = (errorCallback) => new ApolloLink((operation, forward) => {
  const observer = forward(operation);
  // errors will be sent to the errorCallback
  observer.subscribe({ error: errorCallback })
  return observer;
});

const link = reportErrors(console.error);
```

## Extending ApolloLink

```js
import { ApolloLink } from 'apollo-link';

class ReportErrorLink extends ApolloLink {
  constructor(errorCallback) {
    super();
    this.errorCallback = errorCallback;
  }
  request(operation, forward) {
    const observer = forward(operation);
    // errors will be sent to the errorCallback
    observer.subscribe({ error: this.errorCallback })
    return observer;
  }
}

const link = new ReportErrorLink(console.error);
```



