---
title: 使用Expo,Apollo-client,graphcool构建Cnode APP 
date: 2018-01-26 8:53:28
categories: 技术备忘
tags: [expo,Apollo,graphcool,cnode]
---



{{TOC}}

### 项目起因
>技术流程已经建立了，这几天在构建express-mongodb-graqhql的服务器器，花了很长时间，回过头来看又快忘了，感觉到了现在的阶段，人老了，理解能力还是有的，但是记忆力确实不行了。千万要详细记录，要不然就白学很多东西了。 记录越详细越好。

#### 项目缘由
主要是三大块，中间始终贯穿函数式编程的想法，但是有些没有实现

##### Graphcool(Prisma）
在Medium网站查找Ramda的文章，结果首页给我推送，apollo,graphcool的文章，graphcool的图标是绿色的，天生有好感，就想看看到是干什么的，因为前面想着手翻译<Learning GraphQL and Relay>, 这两个技术也很新，所以花了很长时间研究，但是最终没有翻译，感觉到Relay的前景并不是很好，但是最近看Relay还在不断的演化，背靠FB,的确在人才上面和技术上有很大的优势。 但是这个月最终Apollo-Graphcool的构架已经彻底征服了我。 其实选择什么框架并不是什么大问题，没有涉及到核心的问题。这些框架的核心是所有的东西都围绕着GraphQL的`Schema`来展开。刚开始在使用graphcool的Resolver(解析函数)包装Cnode的api的时候，觉得在定义的时候添加`schema`一项是多余的。但是随着学习，我发现，GraphQL的威力就在schema上，有了schema，数据的查询就很厉害了。 所有后边的学习重点就围绕schema展开。Graphcool 1.0版本，代号已经改为Prisma.最终要在这里导入CNODE 的API. 根据Graphcool服务器的schema来进行各项操作

##### Apollo
Apollo 这个构架是在看meteor的时候就已经知道，所以在Medium网站推送时，相关内容也来来，随便看了一下，没有什么概念， 突然就在SegmentFault网上看到一个系列的文章，突然感觉就入门了，这个系列的文章，提到Apollo的客户端在执行异步请求是，是从网络层抽象的，幸运，CCNA满分，很快理解这个构架的优势。Redux中异步请求时的flag突然就没有了，因为这个flag可以直接从请求的网络状态获得，网络层的请求本来就有几个状态。 这个地方解决的太巧妙。  由此就开始了Apollo构架的学习，这个构架实际也包括server，但是所有的server和graphcool相比都逊色不少，配置graphcool的服务器几乎没有花费任何的学习时间，除了resolver的编程。

后面又看到这篇文章[未来的状态管理技术](https://react-apollo.github.io/2018/01/04/the%20future%20of%20state%20mangement/).的确是有未来状态管理的潜力，Redux与之相比有点啰嗦了。其实Redux的技术构架核心，我认为有三个：

- `单一事实来源(数据单向流动)`，
- `Reducer函数(数据Immutable)`，
- `Container(数据注入方式)`

衍生出的`Action`和很多中间件都是为之服务的。  所以只要具有核心可以了，在未来状态的管理技术中提到的`apollo-link-state`这个技术就是依次而生， 本地20%的state和80%的远程数据合二为一，React组件中的所有Action(函数)都依据graphql的`shcema`干活，如果是本地数据`@Client`指令就会阻止Action执行远程的请求，只能用于本地的数据访问。 可以简单理解，在Apollo的`Store`中只加了一个标记就解决了这个问题。

Apollo的技术构架还在不断的演化，前面我的思想中强烈的`Redux`正统思想和Apollo的进步思想一直打架，毕竟在Redux上花了太多的时间和精力，收获还不大。 要舍弃Reducx太难，没办法技术进步太快，要勇于学习新的知识。 说道这里，看到有的文章简介说什么javascript疲劳，现在来看根本没有这回事情。 应该称之为`选择性疲劳`，除了为了框架而框架的项目，但凡GitHub评价很高的项目诞生都是有原因的。了解了技术诞生的原因，就学习就比较简单了。比如前面看了一下Eixlir的东西，没什么概念，为什么会有这么一个语言会存活呢？ 原因就是为了处理高并发和稳定性。 这几天突然想，我已经建了好几个graphcool的服务器，那么如果是我想把这几个服务器用在一个项目呢？例如：从一组关键字['js','ramda','redux','react']中查询结果，那么可以不可以用一个`总的服务器`来接受查询项目，然后下发给`子graphcool`.这样效果是不是会更好？  总的服务器用'Express'可以，`Eixlir`是不是就是为此而生的？  所以学习`Eixlir`的缘由和目标就有了。

##### Expo RN的启动项目

RN本机的配置实在是太麻烦，iOS还好一点，直接装Xcode就可以了，安卓的就不好搞，Expo就是为此而生。 直接create-react-naive-app就生成 Expo-RN项目，手机安装Expo软件，扫码就可以进行调试了。实在是简化了操作。


但是Expo也有自己的问题，它打包了一些子代服务，你用不用都有，所以即使hello world项目也有二十多兆，很大。 我的想法是在expo里使用和调试，但是不用expo自己封装到组件，直接自己安装， 需要的时候可以迁移JS文件的正式的RN项目中。

CNODE的这个expo项目已经有了一些内容实现，所以趁还没忘，记录一下流程和代码。
### 项目流程
#### Graphcool服务构建

##### 服务器初始化
这个实在是太简单.

- `graphcool init` :安装依赖包
- `graphcool deploy` ：部署，本地部署需要docker,mac下的docker用抢先版就可以，远程部署，直接选择就可以了
新的版本[Prisma](https://www.prismagraphql.com/)命令稍微有点改动
- 获取数据库endpoint。随时可以在项目文件夹中用`graphcool info`查看部署信息

#### 创建schema
graphql服务器是以shcema为核心的，schema对于字段类型，和执行方法都有严格的约束，这里严格后面的操作就轻松。
参照Graphcool-framework 的做法
##### 定义scheme
```js
//对于查询cnode api的信息字段的约束条件
type AllCnodePayload {
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
	allCnode(page: Int!, tab: String!): [AllCnodePayload!]!
}
```
在type定义里并没有返回cnode API的 content字段信息。 如果在前端显示列表，content基本是不需要的，或者有需求需要显示摘要， 可以在resolver的时候，做处理。
这样做，graphcool 服务器从api获取的数据虽然包含有content,但是我们用schema过滤掉了。  客户端请求时的数据量就减少了。这个地方体现的就是graphql的灵活性。

在`Query`,中定义了查询时可以传递的参数。`这里没有做关联`，实际是可以做关联的。在Hotel-GeoData的项目中有数据的关联操作。 `tab`参数是用于分类查询的，page这个参数用于分页，由于apollo-client做了很多工作，客户端的分页变得很简单，实际只要处理这个一个参数既可以了，返回的数据和原先的数据拼接在一起就可以了。
**`有一点要注意：如果是client,schema和这里的还不太一样，例如`**

```js
query getFirstPageInformation{
  all: allCnode(page:1,tab:""){
    id,
    title
  },
  share: allCnode(page:1,tab:"share"){
    id,
    title
  },
  job: allCnode(page:1,tab:"job"){
    id,
    title
  },
  dev: allCnode(page:1,tab:"dev"){
    id,
    title
  }
  getWeatherByCity(city:"Beijing"){
    temperature,
    humidity,
    
  }
  
}
```

上面内容拷贝到下面左侧框中，点击执行就可以看到结果

<iframe src="https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allrow-popups allow-scripts allow-same-origin">
</iframe>
客户端的schema可以集各家之大成，一次查询获取所有数据，http只需要做一次请求。

#####  Resolver函数
对于放在REST API之前的 graphcool 服务器， Resolver是核心， 从API获取的信息，在这里根据shcema做处理， 之后就可以使用graphql的各种优点来进行操作。如果认为Graphcool只是做了REST API的代理，认识是非常肤浅的。 
`从Cnode REST API 获取数据并处理的Resolver函数`

```js
require('isomorphic-fetch');
const R = require('ramda');
const url = 'https://cnodejs.org/api/v1/topics';

module.exports = (event) => {
	const { tab, page } = event.data;//这里就是查询的参数，
	//在graphiql，在查询关键词后添加参数，客户端通过apollo-client传递
	
	urlWithParams = `${url}?tab=${tab}&page=${page}`;
	let options = {
		method: 'GET'
	};
	return fetch(urlWithParams, options).then((response) => response.json()).then((responseData) => {
		const NodeList = responseData.data;
		const allCnode = [];
	//去毛处理
		const selectPropertyX = (x) => ({
			id: x.id,
			tab: x.tab,
			aurl: 'https://randomuser.me/api/portraits/thumb/men/97.jpg',
			visit: x.visit_count,
			title: x.title,
			author_id: x.author_id
		});

		 const allCnode = R.map(selectPropertyX, NodeList);
		//const getIdcollections=R.curry(R.map(selectPropertyX,data));
		//const allCnode=getIdcollections(NodeList);

		return { data: allCnode };
	});
};

```

##### graqhiQL测试

graphql优点是带有一个GraphiQL的可视化界面，可以在这里测试一下查询，
用上面的代码块可以获得数据

```js
{
  "data": {
    "getWeatherByCity": {
      "temperature": -4.87,
      "humidity": 93
    },
    "all": [
      {
        "id": "5a2403226190c8912ebaceeb",
        "title": "企业级 Node.js 框架 Egg 发布 2.0，性能提升 30%，拥抱 Async"
      },
      {
        "id": "5a54a8a4afa0a121784a8ab0",
        "title": "玉伯《从前端技术到体验科技（附演讲视频）》"
      },
      {
        "id": "592917b59e32cc84569a7458",
        "title": "测试请发到客户端测试专区，违规影响用户的，直接封号"
      },
      {
        "id": "5a6a47119d371d4a059eee66",
        "title": "北京求推荐一个好的node线下培训课程"
      },
```

上面这个的结果实际是来自两个api的，一个是cnode客户端，一个是天气查询的api.
一次查询就返回了结果。 `这就是graphql的魅力所在`。

#### Expo RN APP 编程
使用Create-react-native-app方法构建导入组件有
- `导航`  react-navigation
- `组件库` react-elements
- `样式库` styled-components  太牛了，这实际也是函数式编程库
- `函数式编程库`：  Ramda, recompose库

主要的思想上的变化是使用函数式编程库。 styled-components的作者问了一个问题，如果函数式编程风格的React组件是无状态组件(函数)，样式也是函数呢？ 由于刚好在学习函数式编程，感觉到黑暗中找到了明灯。  这不就是高阶函数吗？， 样式也可以通过函数传递了。 背后的英雄还是闭包。 
自从学习了Ramada的规范，即每个函数只`解决一个问题`， `函数链从右向左`，`数据从右边开始传递`，之后，感觉以前一团乱麻的想法，慢慢清晰了。  在这个地方，思考问题自动分解了，其实从整体看一团乱麻， 单个函数处理问题并不乱。 引入函数式编程的好处真是无可比拟。 在编程中处理的核心数据结构是数组(Ramda叫List)和对象。围绕这个这两个方面，Ramda有一堆的工具可供使用。 R.curry,R.compose,R.reduce是绝对的核心。 思想方法是分解问题，制造和`配置`生产零件，然后compose成工厂。 在Ramda模式下 compose成的工厂会给在右边留下一个入口，从右边输入猪肉，左边就会后香肠出来。  柯理化和js的闭包在制造和`配置`生产函数时时直观重要的。我一再的强调`配置性` 由于高阶函数的特性，函数可以作为参数传递，所以可以传递行使不同功能的函数来配置成执行不同功能的零件，在背后是js函数闭包负责把配置给你保存起来，备用。  js的函数可配置性使得js中可以使用函数组合成各种不同的工厂，只需要传递数据给它即可工作。  

#### APP 中引入Apollo-client数据层
##### 入口文件引入apollo-client的包和Graphql的 endpoint
Expo/app.js

```js
import React from 'react'
import { StyleSheet } from 'react-native'
import {TabNavigator, StackNavigator, DrawerNavigator} from 'react-navigation'
import { ApolloProvider } from 'react-apollo'
import { ApolloClient, HttpLink, InMemoryCache } from 'apollo-client-preset'
import My from './app/My'
import Message from './app/Message'
import Post from './app/Post'
import Editor from './app/Editor'
import {MyNotificationsScreen, MyHomeScreen} from './app/Drawer'
import Topic from './app/Topic'
import Collection from './app/Collection'

const Drawer = DrawerNavigator({
  Home: {
    screen: MyHomeScreen ,
  },
  Notifications: {
    screen: MyNotificationsScreen ,
  },
})

const  tabNavigator=TabNavigator({
  主题: {
    screen: Collection,
  },
  Notifications: {
    screen: Message,
  },
  Add:{ 
    screen: Editor,
  },
  My:{
    screen: My,
  },
  收藏:{
    screen :Topic
  }
}, {
  tabBarPosition: 'bottom',
  animationEnabled: true,
  tabBarOptions: {
    activeTintColor: '#e91e63',
  },
})

const Navigator = StackNavigator({
  Home: { 
    screen: tabNavigator,
    navigationOptions: {
      title: 'Info',
    },
  },
  Detail: { screen: Post },
  //Setting: { sreen: Drawer},
 
})
//graphcool 服务器的url
const httpLink = new HttpLink({ uri: 'https://api.graph.cool/simple/v1/cjaxudkum2ugf0127kok921bc' })
//构建client对象
const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
  connectToDevTools: false
})
//包装对象注入顶层组件，如果你还要使用Redux,在包装一下，也没有问题。
//分别是两个不同的对象而已。
export default class App extends React.Component {
  render() {
    return (
      <ApolloProvider client={client}>
        <Navigator />
      </ApolloProvider>
    )
  }
}

const  styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center'
  }
})

```

配置其实很简单， 在顶层组件注入apollo-client的对象就可以了。redux的其他的文件夹全没有了。
apollo-client可以和Redux一起工作， 在顶层组件中再次引入Redux的store,也没有问题。因为这两者是独立的。 像是同一个写字楼里的两家公司，虽然在一起，但是各干个的工作，但是也有使用相同组件的地方，例如两家公司可以同时使用一个卫生间。公家的东西显然大家都不太爱惜，很不好。如果两个公司合二为一呢？ 那就好了。 Apollo的团队想到了这个问题。 
`apollo-link-state`就把两拨统一了。 不详细讲，准备翻译apollo的文档了。

##### 组件中的apollo-client的使用
`cnode列表组件`

```js
import React, { Component } from 'react';
import { View, Text, FlatList,Button} from 'react-native';
import { List, ListItem ,Header} from 'react-native-elements';
import Dropdown   from './Drowdown';


//导入graphql组件，具体使用在代码最后
import { graphql } from 'react-apollo';
//tag 用于拼接graphql的语句
import gql from 'graphql-tag';
//拼接的语句，这个语句的效果和在graqhiQL中使用效果是一样的
//查询所有文章的id,title等，schema定义什么就可以返回什么
const allNodesQuery = gql`
  query($page:Int!,$tab:String!) {
    allCnode(page:$page,tab:$tab) {
      id
      title
      tab
      aurl
    }
  }`;
//文章列表组件  
class Topic extends Component {
   
  state = {
    page: 1,
    tab: "",
  }
    render() {
      const {navigate} = this.props.navigation;//react-
      //navigation的导航对象，其实这个就和Redux的store一样，顶层导入的
      //所有的子组件可以使用
      
      console.log(this.props)
      //props会有需要的数据
      //apollo-client神奇的地方， 请求数据的flag借用的是网络层的数据
      //由于这里天然就带有各种状态标记，直接使用就可以了
      //networkStatus===1表示正在请求数据
      if(this.props.networkStatus===1){
        return (
            <View> <Text>Loading...</Text></View>
         )
      }
      return (

        <View>
          <Header  outerContainerStyles={{marginTop:0,zIndex:9999}}
        leftComponent={<Button title={'setting'} onPress={(props)=>
         
          this.props.refetch({ page:1, tab:"job" }) }
         />}
        centerComponent={{ text: 'MY TITLE', style: { color: '#fff' } }}
        rightComponent={<Dropdown refetch={this.props.refetch}/>}
        
        />
        {(this.props.networksStatus===2)&&<View style={{flex:1,alignItems:'center',justifyContent:'center',zIndex:999,opacity:0.8}}>
           <Text>Loading...</Text>
          </View>}
        <List containerStyle={{ borderTopWidth: 0, borderBottomWidth: 0,marginTop:0 }}>
         <FlatList
            data={this.props.allCnode}
            renderItem={({ item }) => (
              <ListItem
                roundAvatar
                refreshing={this.props.networkStatus === 4}
                onRefresh={() => this.props.refetch()}
                title={`${item.title}`}
                subtitle={`${item.tab}`}
                avatar={{ uri: item.aurl }}
                containerStyle={{ borderBottomWidth: 0 }}
                onPress={() => navigate('Detail',{id:`${item.id}`})}
              />
            )}
            keyExtractor={item => item.id}
            onEndReachedThreshold={0.5}
            onEndReached={() => {
        // The fetchMore method is used to load new data and add it
        // to the original query we used to populate the list
        this.props.fetchMore({
          variables: { page: this.props.allCnode.length + 1,tab:"share"},
          updateQuery: (previousResult, { fetchMoreResult }) => {
            // Don't do anything if there weren't any new items
            //console.log(fetchMoreResult)
            if (!fetchMoreResult || fetchMoreResult.allCnode.length === 0) {
              return previousResult;
            }

            return {
              // Concatenate the new feed results after the old ones
              allCnode: previousResult.allCnode.concat(fetchMoreResult.allCnode),
            };
          },
        });
      }}
          />
        </List>
    </View>
      );
    }

    
  }
//这里是graphql注入组件的位置
//options就是初始的参数
//props可以用map方法进行筛选
aooNodesQuery是查询语句
export default graphql(allNodesQuery,{
  options: {
    
    variables: { page:1, tab:"" },
    
  },
  props: ({ ownProps, data: { loading, allCnode, refetch,fetchMore,networkStatus,updateQuery} }) => ({
    Loading: loading,
    allCnode: allCnode,
    refetch: refetch,
    fetchMore: fetchMore,
    networkStatus: networkStatus,
    updateQuer: updateQuery
  }),
}
  )(Topic);

```

上面代码的要点是

1. 使用了网络层的状态来表示请求的状态
2. <Dropdown refetch={this.props.refetch}/> 组件传递了apollo 对象子代的属性方法，refetch用于重新设定 查询的tab.
3. <FlatList  data={this.props.allCnode}  列表组件只需要传入这个数据属性
4.  Item组件解析对象属性,点击即可进入下一页。 具体内容的schema和列表是一差不多的

```js
<ListItem
      roundAvatar
      refreshing={this.props.networkStatus === 4}
      onRefresh={() => this.props.refetch()}
      title={`${item.title}`}
      subtitle={`${item.tab}`}
     avatar={{ uri: item.aurl }}
     containerStyle={{ borderBottomWidth: 0 }}
     onPress={() => navigate('Detail',{id:`${item.id}`})}
              />

```

5. 如果列表到了末端.page变量加 1  `variables: { page: this.props.allCnode.length + 1,tab:"share"}` 
6. 数据返回以后和之前的数据拼接就可以了 `allCnode: previousResult.allCnode.concat(fetchMoreResult.allCnode)`

```js
onEndReached={() => {
        // The fetchMore method is used to load new data and add it
        // to the original query we used to populate the list
        this.props.fetchMore({
          variables: { page: this.props.allCnode.length + 1,tab:"share"},
          updateQuery: (previousResult, { fetchMoreResult }) => {
            // Don't do anything if there weren't any new items
            //console.log(fetchMoreResult)
            if (!fetchMoreResult || fetchMoreResult.allCnode.length === 0) {
              return previousResult;
            }

            return {
              // Concatenate the new feed results after the old ones
              allCnode: previousResult.allCnode.concat(fetchMoreResult.allCnode),
            };
          },

```

![数据请求的状态，true](https://ws2.sinaimg.cn/large/006tNc79ly1fnu2vyl225j308r05dq2y.jpg)

![请求成功以后的状态和数据，到这一步数据以没问题了](https://ws3.sinaimg.cn/large/006tNc79ly1fnu2wks6saj30bs06nwez.jpg)


![文章列表](https://ws3.sinaimg.cn/large/006tNc79ly1fnu2cd2i6xj30hs0qon0m.jpg)


![文章列表下拉刷新的结果](https://ws3.sinaimg.cn/large/006tNc79ly1fnu2zn9vhyj30cz04vt8q.jpg)


### 整个数据数据流程就建立完成了






  

    
    




 
			

			
  



  
  
  

 
