 ---
title: Prisma服务器部署
date: 2018-01-27 12:30:28
categories: 技术备忘
tags: [Grapcool,node.js,Prisma]
---

{{TOC}}

### 缘由
>准备使用Prisma的服务，本来觉得是Graphcool的升级版本，没有什么问题，但是碰到很多问题，奋战一晚，都要睡着了，node.js服务器的报错信息一条都没有了。还是很值得的

在stackflow一搜，有同样问题的人很多。

其实问题很简单，主要的祸首就是Prisma引入的token,原来graphcool没遇到过要toke的情况。

### 流程
####  安装步骤

1. 全局安装prisma ---  `prisma init projectName`
2. 进入server目录 ---  `cd  server`.  
3. 部署 ------------  `prisma deploy`  获得`endpoint`地址
4. 启动本地服务-------   回到项目目录 ，`yarn start` 获得本地服务
5. 获取token--------   `prisma token`   

最坑人的地方是获取token， 用playground的时候需要token，stackflow中很多人遇到这个问题。要在header中设置.
```
{
      "Authorization": "Bearer --token放这里，并删掉短杠--"}
```

后面在使用node服务器的时候也要配置

#### schema的配置
这里还是不太熟悉，新的版本是有优势，但是还没发挥出来，在选择部署的时候，如果是全栈的full stack 的模式，很容易误导人,在movie这个服务器里干脆放弃了，直接使用服务器，结果没有产生歧义，
在database中的`data.model.graphql`中添加`shcema`
从某网站抓取数据的保存的`schema`
```
type  ReactScript {
  id:ID! @unique
  title:String
  url: String
  funcCat:String
  platformCat:String
  dateUpdate:String
  comments:String
  img: String
  excerpt:String
  demoUrl: String
  tag1: String
  tag2: String
  tag3: String
}
```

添加完成后，重新部署，然后，使用地址登录graphiql服务。 这个就遇到为了。要输入上面的token,才行。

输入以后token以后， 如果在右端的schema中看到有 `ReactScript`出现，配置就算完成了，  牢记以shcma为中心，schema中有什么数据结构才可以查询，有什么方法才可使用。配置的方法和结构和预期不一样，根本没有必要进行下去，只会让问题更加的复杂。 schema是一个分水岭，昨天东查查，西看看，浪费不少时间，先在这里把问题做切割。

然后使用手工配置的参数，完成CRUD的操作，看看发方法，模型等是否正常。

如果这里都正常了，但是服务端还有问题，那么根源在后面，prisma就没有什么问题了。

#### node.js graphql-request的使用

这里要配置查询的标签，对着prisma的schema逐个查看，就没有什么问题。 node.js中可能会出现两种错误提示

1.  无法访问服务器， tokent，无效，需要配置，还有现在的endpoint都有`/dev`后缀， 使用时要留心。 
2.  提示查询类型不对， 查询的标签有问题，一定对着查看。 在prisma的版本中，带参数的查询，有点改动，参数之前带了一个`data:{}`， 使用也要注意检查。


#### 这样基本就没有什么问题了
node.js的代码段

<script src="https://embed.cacher.io/d4566dd20434ac12a8af45920c7b1eaf7f59fc10.js?a=879ce6b7a1ff7ace22c8a791e7511f7f&t=github_gist"></script>



 
 