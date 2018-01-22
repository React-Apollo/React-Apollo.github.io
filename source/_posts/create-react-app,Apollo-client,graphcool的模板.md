---
title: create-react-app,Apollo-client,graphcool的模板
date: 2018-01-20 16:18:28
categories: 技术备忘
tags: [cra,Apollo,graphcool]
---
 
 # create-react-app,Apollo-client,graphcool的模板

初步的使用方法，很简单，组要是打通数据线路

代码：
`index.js中的标准配置`
```
import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';
import { ApolloClient } from 'apollo-client';
import { HttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { ApolloProvider } from 'react-apollo';
const client = new ApolloClient({
  link: new HttpLink({ uri: 'https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc' }),
  cache: new InMemoryCache(),
  connectToDevTools: true
});

ReactDOM.render(
  <ApolloProvider client={client}>
    <App />
  </ApolloProvider>,
  document.getElementById('root'),
);

```
React-Native中配置和这个是一样的， 添加了react-navigation时候，完全一样，  所有的路由包装完以后，在用apollo的client包装。Apollo使用时的好处是，虽然数据是单一来源，但是每个容器包装的组件都有查询方法为属性的属性值。 这个很好，相当于有了命名空间， 每个从endpoint获取数据的组件，就等于隔离开了。如果是本地数据考霸是app-link-state的方法。

```
import { graphql} from 'react-apollo';
import gql from 'graphql-tag';

const getOneNode = gql`
  query ($id: String!){
    OneNode(id:$id) {
       id,
       tab,
       content,
       
    }
  }
`;
class App extends Component {
  
  render() {
    console.log(this.props.data);
    if(!this.props.data.loading){
     var content=this.props.data.OneNode.content;
     console.log(typeof(content))
    }else{
      var content = "";
    }
    return (
      <div className="App">
                <div className="App-intro">
        <div>{ReactHtmlParser(content)}</div>;
        </div>

      </div>
    );
  }
}

export default graphql(getOneNode, {options: () => {
  return ({
    variables: {
      id: '5433d5e4e737cbe96dcef312',
      }
  });
}})(App)
```

定要好schema,这个刚开始觉得很难，其实打开graphiql，对着来写是很简单，直观的的  ，可以在graphiql中先获取想要的结果，然后就获得查询的方法了。 剩下就是获取数据了。  这一步已经在Rn-cnode的项目中实现了。  mutate的方法完全相同。


