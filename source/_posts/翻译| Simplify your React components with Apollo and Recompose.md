---
title: 翻译| Simplify your React components with Apollo and Recompose
date: 2018-02-02 19:14:54
categories: 翻译
tags: [Apollo,hoc,Recompose]
---

{{TOC}}

# 使用 Apollo和 Recompse 来简化 React 组件
*使用 hoc 保持组件的纯度*
Apollo client和 Apollo项目的任务之一就是和现代的 React开发者工具无缝对接.这就是卫生我们专注于higher-order components(高阶组件), server-side rendering(服务端渲染),和React Native的原因.

随着日益发展, React的开发者现在集中于开发更小巧,焦点更加集中的组件,由*Andrew Clark* 创建的[**Recompose库**](https://github.com/acdlite/recompose)把这种趋势提高到了更高的高度.当 Andrew Clark 去年在 React Europe 做演讲的时候,他把 Recompose看做是类似 Underscore 和 Lodash 之类的工具集,目标是专门用于 React的组件的开发. 下面是你可以通过 Recompose 所做的事情:

1. 通过纯粹的渲染,优化 React 组件
2. 设定默认值
3. 添加限制性 state 变量

通过使用 React函数式组件的语法,你可以做完成上面的任务.这么做是的代码更加直白,减少了在组件渲染时不小心引入的 state或者复杂度.

经过 `React-apollo`包装的的 React 高阶组件符合这种模式.这些组件只是把一件事做的非常好:即他们让你可以把 GraphQl查询和组件放在一起,并且通过 props 获得数据.其他的事情一概不做,例如管理变量的状态.这时候, React 组件组合, Recompose就可以派上用场了.

![我们可以在一个函数中附加 Graphql 数据, loading管理,变量状态,或者纯粹的渲染](https://ws4.sinaimg.cn/large/006tKfTcgy1fo2c2gwld9j30e2050q2s.jpg)

纷繁芜杂不见了,这里是第一个如何共同使用 Recompose 和 React apollo 的实例.Recompose 和 React apollo一起使拥有 GraphQl 的 UI简明,漂亮.

### 使用`withState`管理变量
函数式组件最好的特征是他们是无状态的.意思是如果提供一套同样的props,你总是会得到同样的输出结果,这样就使得组件容易预测和测试.然而,有时候,你还是需要使用一些临时的 state,组好是能把这些东西放在执行渲染的组件之外,保持事情简单化.

让我们来看看如何使用`withState`容器构建一个具有搜索框(search box)和 Graphql 查询的 React 组件:

```js
import React from 'react';
import { withState, pure, compose } from 'recompose';
import gql from 'graphql-tag';
import { graphql } from 'react-apollo';
import { Link } from 'react-router';

// The data prop, which is provided by the wrapper below, contains
// a `loading` key while the query is in flight, and the bookSearch
// results when they are ready
const BookSearchResultsPure = ({ data: { loading, bookSearch } }) => {
  if (loading) {
    return <div>Loading</div>;
  } else {
    return (
      <ul>
        {bookSearch.map(book =>
          <li key={book.id}>
            <Link to={`/details/${book.id}`}>
              {book.title} by {book.author.name}
            </Link>
          </li>
        )}
      </ul>
    );
  }
};

// The `graphql` wrapper executes a GraphQL query and makes the results
// available on the `data` prop of the wrapped component.
//
// Note that if you type a search field and then hit backspace, the
// Apollo cache kicks in and no actual data loading is done.
const data = graphql(gql`
  query BookSearchQuery($keyword: String!) {
    bookSearch(keyword: $keyword) {
      id
      image
      title
      author {
        id
        name
      }
    }
  }
`, {
  // The variable $keyword for the query is computed from the
  // React props passed to this container.
  options: (props) => ({
    variables: { keyword: props.keyword },
  }),
});

// Attach the data HoC to the pure component
const BookSearchResults = compose(
  data,
  pure,
)(BookSearchResultsPure);

// Use recompose to keep the state of the input so that we
// can use functional component syntax
const keyword = withState('keyword', 'setKeyword', '');

const BookSearchPure = ({ keyword, setKeyword }) => (
  <div>
    <input
      type="text"
      value={ keyword }
      onChange={(e) => setKeyword(e.target.value)}
    />

    <BookSearchResults keyword={keyword} />
  </div>
);

// Attach the state to the pure component
const BookSearch = compose(
  keyword,
  pure,
)(BookSearchPure);

export default BookSearch;
```



import TodoList from '../components/TodoList/TodoList'
const  Comp=(todos)=>
  <TodoList todos={todos}/>
function mapStateToProps(store) { 
  return {
    todos: store.todolist
    };
}

export default connect(mapStateToProps)(Comp);




