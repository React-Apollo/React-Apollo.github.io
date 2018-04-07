---
title: Apollo|Stateful Links
date: 2018-03-22 10:37:07
categories: 技术备忘
tags: [GraphQL,Apollo]
---

# Stateful Links

某些 Link 需要在请求之间共享 state,从而完成额外的功能. 
Stateful links 总是重写`ApolloLink`

```js
import { ApolloLink } from 'apollo-link';

class OperationCountLink extends ApolloLink {
  constructor() {
    super();
    this.operations = 0;
  }
  request(operation, forward) {
    this.operations++
    return forward(operation);
  }
}

const link = new OperationCountLink();
```




