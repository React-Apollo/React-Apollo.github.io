---
title: 使用Expo,Apollo-client,graphcool构建Cnode APP 
date: 2017-01-26 8:53:28
categories: 技术备忘
tags: [expo,Apollo,graphcool,cnode]
---



{{TOC}}

### 项目起因
>技术流程已经建立了，这几天在构建express-mongodb-graqhql的服务器器，花了很长时间，回过头来看又快忘了，感觉到了现在的阶段，人老了，理解能力还是有的，但是记忆力确实不行了。千万要详细记录，要不然就白学很多东西了。 记录越详细越好。

#### 项目缘由
主要是三大块，中间始终贯穿函数式编程的想法，但是有些没有实现

##### Graphcool(Prisma）
在Medium网站查找Ramda的文章，结果首页给我推送，apollo,graphcool的文章，graphcool的图标是绿色的，天生有好感，就想看看到是干什么的，因为前面想着手翻译<Learning GraphQL and Relay>, 这两个技术也很新，所以花了很长时间研究，但是最终没有翻译，感觉到Relay的前景并不是很好，但是最近看Relay还在不断的演化，背靠FB,的确在人才上面和技术上有很大的优势。 但是这个月最终Apollo-Graphcool的构架已经彻底征服了我。 其实选择什么框架并不是什么大问题，没有涉及到核心的问题。  这些框架的核心是所有的东西都围绕着GraphQL的`Schema`来展开。刚开始在使用graphcool的Resolver(解析函数)包装Cnode的api的时候，觉得在定义的时候添加`schema`一项是多余的。但是随着学习，我发现，GraphQL的威力就在schema上，有了schema，数据的查询就很厉害了。 所有后边的学习重点就围绕schema展开。Graphcool 1.0版本，代号已经改为Prisma.r

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
```
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

在`Query`,中定义了查询时可以传递的参数。`这里没有做关联`，实际是可以做关联的。在Hotel-GeoData的项目中有数据的关联操作。
**`有一点要注意：如果是client,schema和这里的还不太一样，例如`**

```
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
  getWeatherByCity(city:"zhangjiang"){
    temperature,
    humidity,
    
  }
```
客户端的schema可以集各家之大成，一次查询获取所有数据，http只需要做一次请求。

#####  Resolver函数
对于放在REST API之前的 graphcool 服务器， Resolver是核心， 从API获取的信息，在这里根据shcema做处理， 之后就可以使用graphql的各种优点来进行操作。如果认为Graphcool只是做了REST API的代理，认识是非常肤浅的。 
`从Cnode REST API 获取数据并处理的Resolver函数`

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

```
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
#### APP 中引入Apollo-client数据层

--未完成--


  

    
    




 
			

			
  



  
  
  

 
