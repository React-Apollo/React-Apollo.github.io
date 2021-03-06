---
title: PocketerCRA项目说明
date: 2018-01-23 20:18:28
categories: 技术备忘
tags: [ graphql]
---
# Pocketer-CRA项目说明
## 主要技术介绍
> 使用graphql和mongodb和 create-react-app构建的项目
> 分为三部分:

> - `①`.网站内容抓取并存入到mlab数据库 
> - `②`.构建graphql-server服务器提供查询服务，后台通过mongoose和mlab交互，获取查询信息。
> - `③`.前端的CRA程序，使用react-apollo-hooks和graphql服务器交互获取查询信息

##  网站内容抓取
### 程序组成信息
通过 [`http://gdom.graphene-python.org/graphql`](http://gdom.graphene-python.org/graphql) 
获取Pocketer的内容信息。 这是`request`模块需要的`graphql服务器`地址url地址.

Dom结构如下：

```
const getList = `query getList($url:String!){
    page(url: $url) {
        List: 
           query(selector: "#best_of_list ul li .item_content") {
           title: text(selector: ".title a")
           source: text(selector: "cite a")
           time: text(selector: "cite span")
           url: attr(selector: ".title a", name: "href")
           excerpt: text(selector: ".excerpt")
        }
    }
}`;
```

传入要抓取网站的链接，填入要获取信息的dom结构信息。这是`request`模块需要的的template信息.

### 代码结构
**request 函数柯里化**

```
//使用Ramda 柯里化 request函数的参数
const handleGrqphcoolDataTemplate = R.curry(
    (api, template, variables) => (
        request(api, template, variables).then(data => {
          return data;
        })
    )
)

//柯理化的函数先传递 graphql服务器的地址和schema,等待 url 变量

const queryData = handleGrqphcoolDataTemplate(gDomApi,getList);

```

**传入url地址到获取整个抓取对象的数据流，ramda的compose函数负责从右向左传递数据**

```
//1 拼接链接字符串
const  getUrlStringOfpocket=(str="javscript")=>`{"url":"https://getpocket.com/explore/${str}?src=search"}`; 
// 2 格式化模板json化
const JsonFormat = (UrlString) => JSON.parse(UrlString);

//3  查询数据
const queryPages = (queryStr) => queryData(queryStr) 
//4 数据脱括号的方法,去掉前面的几层花括号的层级 
const getArray =async (obj) => obj.page.List;
//然后传入等待链接的graphql查询函数,使用异步compose,从右向左执行流程
const getPagesArray = asyncompose(getArray,queryPages,JsonFormat,getUrlStringOfpocket); 
```



**‌借助Mongoose插入数据到mlab 数据库**
`config.js`

```javascript
const mongoose = require('mongoose');
mongoose.Promise = global.Promise;

const   MONGO_URL='mongodb://user:user1234@ds048368.mlab.com:48368/pocket-excerpt';

mongoose.connect(MONGO_URL, { useNewUrlParser: true });
mongoose.connection.once('open', () => console.log(`Connected to mongo at ${MONGO_URL}`));
```
在`config.js`文件中配置mlab数据库和mongoose配置,mongoose需要设置schema，mongoose的schema和Graphql的schema很相似，所以一起使用很方便

```javascript
const mongoose = require('mongoose');
const { Schema } = mongoose;

const News = new Schema({
  cate:String,
  title: String,
  source: String,
  time: String,
  url:String,
  excerpt:String,
});

const newsModel = mongoose.model('News', News); 

module.exports = {
  newsModel
};
```

创建的额newModel模型性对象就挂在了根据schema操作mongodb的方法。直接执行及㐓了

**插入操作**

```javascript
const dbForData= async (args)=>{
           newsModel.create(args); //插入数据
           log(chalk.green('insert %s'),args.title);
    };
```

只只要提供的参数和schema的一样，插入就很简单，只要一个`model.create(args)`就可以了。

模型中定义了cate，用于pocketer的分类， 所以在从网站抓取的信息中添加这个cate字段

```
//获取的数据
const Array= await getPagesArray(str);
           //const db= await dbForData(_) ;
           
           //遍历对象添加查询字符串作为分类标记
           const addCate=  (obj)=>{
                return Object.assign({}, obj, {
                    cate: cate,
                })
            }
//遍历获取的数组每篇文章的信息，添加cate字段
const ArrayaddCate=  Array.map(addCate);
```


**遍历数组，执行插入操作**

```
await  R.map(dbForData,ArrayaddCate);
```

以上代码是单个搜索字符串的插入结果，每个字符串下面可以查到很多文章。 相当于单个售票窗口的队列。 但是我们可以传入多个字符串，这就相当于售票处开了多个窗口。多个窗口之间的操作是并行执行的。 在单个窗口的操作其实也可以是并行操作。这里没有考虑。

执行多个字符串的操作，代码如下：


```
const  insertData= async (items)=> {
     //items是传入的多个字符串   
        const promises = items.map((item) => getData(item));
        await Promise.all(promises);
        log(chalk.yellow('Total Done !'));     
    }

    await  insertData(searchkeywords);
```

上面代码中items就是传入的多个查询字符串组成的数组， 遍历它，因为数组中每个字符串元素返回的都是promise对象， 使用map方法组成promise数组，
然后使用Promise.all方法并行执行操作。

**‌单个字符串的流程还要修改一下，每篇文章的操作仍然是并发的**


## 本地的graphql-server的构建
使用了apollo-graphql-express构建

提供 `typeDefs`和`resolvers`就可以了。 服务器接受执行指令， 然后在resolvers中执行数据库操作，然后返回Graphql结果

**graphql参数定义**


```
const typeDefs = gql`
    type News {
        id: ID!
        cate:String,
        title: String,
        source: String,
        time: String, 
        url:  String ,
        excerpt: String,
    }

    type Query {
        getAllNews: [News]
    }
    type Mutation {
        addOneNews(
            cate:String,
            title: String, 
            source: String,
            time:String,
            url: String,
            excerpt: String,
        ): News
    }
`;
const resolvers = {
    Query: {
        getAllNews: async () => await newsModel.find({}).exec()
    },
    Mutation: {
        addOneNews: async (_, args) => {
            try {
                console.log(args);
                let response = await newsModel.create(args);
                return response;
            } catch(e) {
                return e.message;
            }
        }
    }
};
```

**graphQL服务器初始化**

```
const server = new ApolloServer({ typeDefs, resolvers });
const app = express();
server.applyMiddleware({ app });

app.listen({ port: 4000 }, () =>
  console.log(`🚀 Server ready at http://localhost:4000${server.graphqlPath}`)
);
```


## Create-React-App 构建
添加了styled-components,reactstrap,react-apollo-hooks。

