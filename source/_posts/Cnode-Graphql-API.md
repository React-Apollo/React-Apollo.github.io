---
title: cnode GraphQL 版本
date: 2018-03-02 16:35:42
categories: 技术备忘
tags: [Graphcool,Prisma,cnode]
---

![](https://ws2.sinaimg.cn/large/006tNc79gy1foyjtzn99aj30qn082wee.jpg)


>按照[cnode-api](https://cnodejs.org/api)的顺序来的, 基本只是做了包装,
需要修改的可以看代码,做出修改. 通过 graphql 的 rest-wrapper  resolver 包装以后,就可以获得 graphql的一些很好的特征了.   因为没有数据写入的Grpahql 的数据库,所以所有的操作都用的是query. 没有用 mutate. 因为最终还是访问的 REST API.  
这的graphql采用的是 graphcool 的服务器, 尽管试, 没有写入操作.

 [`Graphcool-cnode-server graphiQL地址`](https://api.graph.cool/simple/v1/cje86sc3a3p1d0140rkquung1) 
 
 服务器的初始化可以参考这里[`Graphcool Server`](https://www.graph.cool/)  
 
 
 
 可以选择部署在本地docker 中, 如果用于测试可以 直接部署在云上. 
 
大致的流程如下在 GraphQL客户端或者是 GraphiQL执行的操作,会经过 resolver 函数的处理, resolver 实际是 express 服务器, 在这里可以执行数据库操作,或者是执行转发任务,  如果是为 API 提供服务, 就使用转发. 我们这里就是转发.


## 主题
###  `1` get/tpoics  主题首页
就是数据列表,tab用于分类, page 用于分页

`allTopics.graphql`

```
//⛔️有些字段没有列出,可以做修改
type AllTopicsPayload {
  id: String!
	tab: String
	title: String!
	visit: Int!
	aurl: String!
	author_id: String!
}

input QueryInput {
	page: Int!
	tab: String!
}

extend type Query {
	AllTopics(page: Int!, tab: String!): [AllTopicsPayload!]!
}

```

`allTopics.js`

```
require('isomorphic-fetch');
const R = require('ramda');

const url = 'https://cnodejs.org/api/v1/topics';

module.exports = (event) => {
	const { tab, page } = event.data;
	urlWithParams = `${url}?tab=${tab}&page=${page}`;
	let options = {
		method: 'GET'
	};
	return fetch(urlWithParams, options).then((response) => response.json()).then((responseData) => {
		const NodeList = responseData.data;
		const allCnode = [];
			const selectPropertyX = (x) => ({
			id: x.id,
			tab: x.tab,
			aurl: x.author.avatar_url,
			visit: x.visit_count,
			title: x.title,
			author_id: x.author_id
		});

		const allTopics = R.map(selectPropertyX, NodeList);
		//const getIdcollections=R.curry(R.map(selectPropertyX,data));
		//const allCnode=getIdcollections(NodeList);

		return { data: allTopics };
	});
};

```

查询示意图
![](https://ws2.sinaimg.cn/large/006tNc79gy1foygnhz9orj30dg0e5q2t.jpg)

**`注意事项`**
`graphiQL里执行的操作就是最好的文档, 这里执行的查询结果, 在其他地方可以完全复现,如果复现不了,就是你的客户端代码由问题. 在客户端我们可以使用 graphql-tag 的方法把这段查询的字符串给拼接出来.如果拼接没有问题, 得到的结果是完全一样的`

### `2` get/topics主题详情

 `getOneTopic.graphql`
 
```js
 type OneTopicPayload {
  id: String!
  tab: String
  title: String!,
  content:String!,
}

extend type Query {
   getOneTopic(id:String!): OneTopicPayload!
}
```

`getOneTopic.js`

```js
require('isomorphic-fetch')
const R = require('ramda');

module.exports = event => {
  const {id} = event.data
  const url = `https://cnodejs.org/api/v1/topic/${id}`

  return fetch(url)
    .then(response => response.json())
    .then(responseData => {
      return {data: responseData.data}

    })
}

```

`查询`

![](https://ws3.sinaimg.cn/large/006tNc79gy1foyh2hhju2j30bi0eo0sl.jpg)


### `3`新建主题 post/topics

`createTopic.graphql`

```
type createTopicPayload {
  tab: String!@default(value: "dev") #默认选了 dev
  title:String!
  accesstoken: String!
  content: String!
  success: Boolean
  
}

extend type Query {
  createTopic(title: String!,accesstoken:String!,tab:String!,content:String!): createTopicPayload
}

```

`createTopic.js`

```js
'use latest'
import fetch from 'node-fetch'
const api = 'https://cnodejs.org/api/v1/topics' 
module.exports = async event => {
  const {tab, accesstoken, title, content} = event.data
  const body = {
    accesstoken: accesstoken,
    tab: tab,
    title: title,
    content: content
  }
  const ress = await fetch(api, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    })
    .then(res => res.json())
    .then(json => json)
  const success = {
    'success': ress.success
  }
  console.log(ress);
  return {data: success}
}

```

`查询示意`
![](https://ws1.sinaimg.cn/large/006tNc79gy1foyheh3ggfj30w30gymxb.jpg)

### `4`编辑主题 post/topics/update

`updateTopic.graphql`

```js
type updateTopicPayload {
    tab: String!@default(value: "dev")
    title:String!
    accesstoken: String!
    content: String!
    success: Boolean
    topic_id:String!
  
}

extend type Query {
    updateTopic(title: String!,accesstoken:String!,tab:String!,content:String!,topic_id:String!): updateTopicPayload
}


```

`updateTopic.js`

```js
'use latest';
import fetch from 'node-fetch';
const api = 'https://cnodejs.org/api/v1/topics/update';
module.exports = async event => {
	const { tab, accesstoken, title, content, topic_id } = event.data;
	const body = {
		accesstoken: accesstoken,
		tab: tab,
		title: title,
		content: content,
		topic_id: topic_id
	};
	const ress = await fetch(api, {
		method: 'POST',
		body: JSON.stringify(body),
		headers: { Accept: 'application/json', 'Content-Type': 'application/json' }
	})
		.then(res => res.json())
		.then(json => json);
	const success = {
		success: ress.success
	};
	console.log(ress);
	return { data: ress };
};

```

`查询结果`
和创建基本是一样的


## 收藏



###  `1`收藏主题   get topic_collection/collect

`createTopicCollection.graphql`

```
type createTopicCollectionPayload {
  topic_id: String
  accesstoken: String
  success: Boolean
  
}

extend type Query {
  createTopicCollection(topic_id: String!,accesstoken:String!): createTopicCollectionPayload
}
```

`createTopicCollection.js`

```js
'use latest'
import fetch from 'node-fetch'
const api = 'https://cnodejs.org/api/v1/topic_collect/collect'
module.exports = async event => {
  const {topic_id, accesstoken} = event.data
  const body = {
    accesstoken: accesstoken,
    topic_id: topic_id
  }
  const ress = await fetch(api, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    })
    .then(res => res.json())
    .then(json => json)
  const success = {
    'success': ress.success
  }
  return {data: success}
}

```


###  `2`取消主题收藏  post/topic_collection/de_collect

`cancelTopicCollection.graphql`

```
type cancelTopicCollectionPayload {
  topic_id: String
  accesstoken: String
  success: Boolean
  
}

extend type Query {
  cancelTopicCollection(topic_id: String!,accesstoken:String!): cancelTopicCollectionPayload
}
```

`cancelTopicCollection.js`

```js
'use latest'
import fetch from 'node-fetch'
const api = 'https://cnodejs.org/api/v1/topic_collect/de_collect'
module.exports = async event => {
  const {topic_id, accesstoken} = event.data
  const body = {
    accesstoken: accesstoken,
    topic_id: topic_id
  }
  const ress = await fetch(api, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    })
    .then(res => res.json())
    .then(json => json)
  const success = {
    'success': ress.success
  }
  return {data: success}
}

```
![](https://ws1.sinaimg.cn/large/006tNc79gy1foyi1uy2aij30vz096q2v.jpg)


### `3` 主题首页 get/topic_collection/:loginname

`allCollections.graphql`

```js
type AllCollectionsPayload {
  id: String!
  tab: String
  title: String!
  visit:  Int!
  
}
extend type Query {
  AllCollections(name:String!): [AllCollectionsPayload !]!
}
```

`allCollections.js`

```
require('isomorphic-fetch')
const R = require('ramda')

const url = 'https://cnodejs.org/api/v1/topic_collect/'

module.exports = (event) => {
  const {name} = event.data
  urlWithParams = `${url}${name}`
  let options = {
    method: 'GET'
  }
  return fetch(urlWithParams, options).then((response) => response.json()).then((responseData) => {
    
    const Collections = responseData.data
    const selectPropertyX = (x) => ({id: x.id, tab: x.tab, title: x.title, visit: x.visit_count, author_id: x.author_id})
    const allCollections = R.map(selectPropertyX, Collections)
    return {data: allCollections}
  })
};

```

`查询结果`
![](https://ws4.sinaimg.cn/large/006tNc79gy1foyhlyxolvj30wc0f9t8v.jpg)

## 评论

### `1` 新建评论  post/ topic/:topic_id/replies

`createReplies.graphql`

```
type createRepliesPayload {
     topic_id:String!
     accesstoken:String!
     content: String!
     reply_id: String 
     success:Boolean
  
}

extend type Query {
  createReplies(topic_id: String!,accesstoken:String!,content:String!,reply_id:String): createRepliesPayload
}
```

`createReplies.js`

```js
'use latest'
import fetch from 'node-fetch'
module.exports = async event => {
  const {topic_id, accesstoken, content, reply_id} = event.data
  const body = {
    accesstoken: accesstoken,
    content: content,
    reply_id: reply_id
  }

   const  api=`https://cnodejs.org/api/v1/topic/${topic_id}/replies`
  const ress = await fetch(api, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}
      })
    .then(res => res.json())
    .then(json => json)
  const success = {
    'success': ress.success
  }
  console.log(ress)
  return {data: success}
}
```

`查询结果`

![](https://ws3.sinaimg.cn/large/006tNc79gy1foyiae6bk2j30vj09w0sp.jpg)

### `2`为评论点赞  post /reply/:reply_id/ups

`createUps.graphql`

```js
type createUpsPayload {
     
     accesstoken:String!
     reply_id: String!
     success:Boolean
     
  
}

extend type Query {
  createUps(accesstoken:String!,reply_id:String): createUpsPayload
}


```

`createUps.js`

```js
'use latest'
import fetch from 'node-fetch'

module.exports = async event => {
  const { accesstoken, reply_id} = event.data
  const body = {
    accesstoken: accesstoken
  }

  const api = `https://cnodejs.org/api/v1/reply/${reply_id}/ups`
  const ress = await fetch(api, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}
    
  })
    .then(res => res.json())
    .then(json => json)
  const success = {
    'success': ress.success
  }
  console.log(ress)
  return {data: success}
}

```

`查询结果`
![](https://ws2.sinaimg.cn/large/006tNc79gy1foyif3w6pgj30vf0640sm.jpg)

## 用户
### `1`用户详情  get /user/:loginname

`getUserInfo.graphql`

```js
type UserInfoPayload {
  loginname:  String!
  avatar_url: String!
  score: Int!
  recent_topics:[Json!]!
  recent_replies:[Json!]!
}


extend type Query {
  getUserInfo(name:String!): UserInfoPayload!
}

```

`getUserInfo.js`

```js
require('isomorphic-fetch')


const url = 'https://cnodejs.org/api/v1/user/'

module.exports =async  (event) => {
  const {name} = event.data
  urlWithParams = `${url}${name}`
  let options = {
    method: 'GET'
  }
  return fetch(urlWithParams, options)
    .then(response => response.json())
    .then(responseData => {
      return {data: responseData.data}
    })
}

```

`查询结果`
![](https://ws2.sinaimg.cn/large/006tNc79gy1foyik5nltrj30va083jrd.jpg)

## 消息通知

### 获取未读消息  get/message/count

`getMessageCount.graphql`

```js
type MessageCountPayload {
    accesstoken:String!
    data:Int
    success:Boolean
}
extend type Query {
  getMessageCount(accesstoken:String!): MessageCountPayload!
}
```

`getMessageCount.js`

```js
require('isomorphic-fetch')
const url = 'https://cnodejs.org/api/v1/message/count?accesstoken='

module.exports =async  (event) => {
  const {accesstoken} = event.data
  urlWithParams = `${url}${accesstoken}`
  let options = {
    method: 'GET'
  }
  return fetch(urlWithParams, options)
    .then(response => response.json())
    .then(responseData => {
      return {data: responseData}
    }) 
}

```
![](https://ws4.sinaimg.cn/large/006tNc79gy1foyiygfa1cj30vm05b0sl.jpg)

### `2`获取已读和未读消息  get /messages

`getMessages.graphql`

```js
		type MessagesPayload {
    
    has_read_messages:[Json]
    hasnot_read_messages:[Json]
    
}


extend type Query {
  getMessages(accesstoken:String!): MessagesPayload!
}
```

`getMessages.js`

```js
require('isomorphic-fetch')
const url = 'https://cnodejs.org/api/v1/messages?accesstoken='

module.exports =async  (event) => {
  const {accesstoken} = event.data
  urlWithParams = `${url}${accesstoken}`
  let options = {
    method: 'GET'
  }
  return fetch(urlWithParams, options)
    .then(response => response.json())
    .then(responseData => {
      return {data: responseData.data}
    })
}
```

`查询结果`
![](https://ws4.sinaimg.cn/large/006tNc79gy1foyj2ztwdlj30w008i3yh.jpg)

### `3`全部标记已读  post /message/mark_all

`markAll.graphql`

```js
type markAllPayload {
    
    accesstoken: String!
    success: Boolean
}
extend type Query {
    markAll(accesstoken:String!): markAllPayload
}
```

`markAll.js`

```js
'use latest';
import fetch from 'node-fetch';
const api = 'https://cnodejs.org/api/v1/message/mark_all';
module.exports = async event => {
	const {accesstoken} = event.data;
	const body = {
		accesstoken: accesstoken,
		
	};
	const ress = await fetch(api, {
		method: 'POST',
		body: JSON.stringify(body),
		headers: { Accept: 'application/json', 'Content-Type': 'application/json' }
	})
		.then(res => res.json())
		.then(json => json);
	const success = {
		success: ress.success
	};
	console.log(ress);
	return { data: ress };
};
```

`查询结果`
![](https://ws2.sinaimg.cn/large/006tNc79gy1foyj6o4r71j30vb055wec.jpg)



## 后记,如果要在 客户端使用 GraphQL查询,怎么操作呢?
我使用的的 Apollo-client的方法

### `①` 在顶层组件导入配置文件

```
import { ApolloProvider } from 'react-apollo'
import { ApolloClient, HttpLink, InMemoryCache} from 'apollo-client-preset'

const httpLink = new HttpLink({ uri: 'https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc' })

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
  connectToDevTools: false
})

export default class App extends React.Component {
  render() {
    return (
      <ApolloProvider client={client}>
        <Navigator />
      </ApolloProvider>
    )
  }
}
```

### `②`实际是单一数据来源的 store, 在组件中可以直接使用查询了

```
import { graphql } from 'react-apollo';
import gql from 'graphql-tag';
//这里拼接的查询字符串和我们在浏览器中使用的字符串完全相同
//如果在浏览器中正常,这里没有结果,或者结果不一致, 问题就在这里了.
const getCollections = gql`
  query ($name: String!){
    AllCollections(name:$name) {
       id,
       tab,
       title,
       visit
       
    }
  }
`;

class Collection extends Component {
    componentDidMount() {
         
    }
    render() {
      const {navigate} = this.props.navigation;
      //console.log(this.props.data)
      if(this.props.data.loading){
        return (
            <View style={{flex:1,alignItems:'center',justifyContent:'center'}}>
              <Text>Loading...</Text>
            </View>
        )
      }
      //console.log(this.props.data.AllCollections);
      return (
        <List containerStyle={{ borderTopWidth: 0, borderBottomWidth: 0 }}>
          <FlatList
            data={this.props.data.AllCollections}
            renderItem={({ item }) => (
              <ListItem
                roundAvatar
                title={`${item.title}`}
                subtitle={`访问次数:${item.visit}`}
                avatar={{ uri: "https://avatars3.githubusercontent.com/u/3118295?v=4&s=120" }}
                containerStyle={{ borderBottomWidth: 0.2 }}
                onPress={() => navigate('Detail',{id:`${item.id}`})}
              />
            )}
            keyExtractor={item => item.id}
            onEndReachedThreshold={50}
          />
        </List>
      );
    }
  }
 //注入 graphql 查询
  export default graphql(getCollections, {options: ({navigation}) => {
  
    return ({
      variables: {
        name: 'alsotang',
       
      }
    });
  }})(Collection)

```


## GraphQL在这里不仅仅是对 API进行了包装这么简单,它大概提供了一下的好处:

- `①`:严格了类型,类型错误,或者缺少都会报错
- `②`:可以根据需求灵活的选择需要返回的数据,例如 列表并不需要 cotent,我们可以选择性的在 graphql 返回数据时省掉这一个字段. 如果 graphQL 服务器和 REST 服务器在同一个主机下,效率会大大提高. 
- `③`:为 API生成了一个单一的入口,多个查询可以一次返回.  减少请求次数
- `④`: 提供了强有力的测试和说明工具: graphiql, 统一前后端的操作. 
- `⑤`: graphQL自带说明性质, 有很好的代码提示和自动完成功能. 后续的客户端也会提供这个功能, 出错的机会大大降低了







