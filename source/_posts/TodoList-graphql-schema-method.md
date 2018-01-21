---
title: TodoList-graphql-model
date: 2018-1-20 6:30:28
categories: Data Model
tags: [graphql,data-Model]
---

#  基础的graphql数据模型
网址是：[grapiql](https://todo-mongo-graphql-server.herokuapp.com/)

[![Edit GraphqlHub](https://codesandbox.io/static/img/play-codesandbox.svg)](https://codesandbox.io/s/0q1lr91lml)
<iframe src="https://codesandbox.io/embed/0q1lr91lml" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"></iframe>
### 数据模型
```json
id: ID
title: String
completed: Boolean
```

* query :todos{id, title, complete}
* mutation:

```
- add(title: String!): todo
- toggle(id: String!): todo
- toggleAll(checked: Boolean!): [todo]
- destroy(id: String!): todo
- clearCompleted: [todo]
- save(id: String!title: String!): todo
```
<iframe src="https://todo-mongo-graphql-server.herokuapp.com" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin">TodoList Demo</iframe>
                   `TodoList Demo`
<iframe src="https://untitled-j7n6hjzk33ty.runkit.sh/graphiql" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"> </iframe>
             `runkit  graphql  playground`