---
title: 翻译|React & Redux Tutorial — Build a Hacker News Clone
date: Thursday, December 20, 2018 at 9:28:50 AM China Standard Time
categories: 技术备忘
tags: [React,Redux]
---


# 翻译|React & Redux Tutorial — Build a Hacker News Clone
##### -- Build a production React project using Redux and Styled Components. Deploy the app using GitHub pages.

[原文参见](https://levelup.gitconnected.com/react-redux-tutorial-build-a-hacker-news-clone-64f320364f85)

本文是 [gitconnected Hacktobrefest项目](https://gitconnected.com/hacktoberfest)的逐步解决方法.

在本教程中,我将会构建一个产品级别的的 Hacker News 克隆. 我们会逐步实现应用的初始化,添加用于状态管理的 Redux,用 React 构建 UI并且部署到 GitHub 主页上.样式将会采用[`styled-components](https://www.styled-components.com/),API方面使用[`axios`](https://github.com/axios/axios)库调用 [`Hacker News API`](https://github.com/HackerNews/API).

[`源代码在这里查看`](https://github.com/gitconnected/hacker-news-reader).

[`下载 Chrome应用`](https://chrome.google.com/webstore/detail/hacker-news/hknoigmfpgfdkccnkbfbjfnocoegoefe?pli=1&authuser=1)


![](https://ws4.sinaimg.cn/large/006tNbRwgy1fycyouhuf9j30gl091dg7.jpg)

如果你愿意看视频,可以看看 youtube 上的教程. [http://www.youtube.com/watch?v=oGB_VPrld0U&index=2&list=PLTTC1K14KAxHj6AftnRUD28SQaoVauvl3](http://www.youtube.com/watch?v=oGB_VPrld0U&index=2&list=PLTTC1K14KAxHj6AftnRUD28SQaoVauvl3)

## 初始化项目

使用[`create-react-app`](https://github.com/facebook/create-react-app)来初始化项目.用这个包初始化项目,就不用担心配置问题了.首先要确定已经安装了`create-react-app`.

```bash
npm -i -g create-react-app
```

运行下面的命令来启动项目. `create-react-app` 安装了所有构建 React 应用的必备依赖包,还有默认的脚本用于管理开发和实际应用的打包.

```bash
create-react-app hn-clone

# wait for everything to finish...

cd hn-clone
```

现在可以安装应用所需的核心软件包了.目前我使用的是`yarn`来管理依赖包,如果你使用的是`npm`,只需要用`npm install`替换掉`yarn add`就可以了.

```bash
yarn add redux styled-components react-redux redux-logger redux-thunk axios
```

`create-react-app`使用`NODE_PATH` 环境变量(environment variable)来创建绝对路径. 我们可以在`.env`文件中声明环境变量. `create-react-app`会识别它,通过[`doten库`](https://www.npmjs.com/package/dotenv) 来应用绝对路径.

```bash
#使用touch 命令创建.env文件

touch .env
# 在.env文件里添加
#NODE_PATH=src
```

如果你对这个模式不太熟悉, 当我们开始构建应用的时候,对你来说更为有意义.设定环境变量可以让我们直接导入文件而不用考虑文件的路径. 类似这样 `../../components/List` 变为`components/List`- 使用上方便多了.


## 文件组织结构

在`src`文件夹里面, 从应用要适应更为大规模和重用性更强上考虑,做一些更新.

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fycz8a95cyj30fc0jkglu.jpg)

- `components`: 这个文件夹包含所有的 React 组件(container和 presentational 组件都包含).
- `services`: Services可以连接到API(例如,使用axios调用 HN API)或者为应用提供扩展的功能(例如,添加markdown)支持.
- `store`: store 包含了所有的Redux和state 管理的逻辑
- `styles`: 在styles文件夹内,我们声明变量,模板和可以在组件间共享的样式模式
- `utils`: 整个应用中可以重用的助手函数

这里的文件夹结构有两个地方值得注意:

1. 应用中只有一个路由,位于根`./`下.如果我们有多个路由,我可能会使用`react-router`包,同时创建`pages`文件夹用于保存页面级别的组件.
2. 我没有使用单独的`container`文件夹用于连接应用组件到Redux.我发现增加`container`文件夹反而添加了不必要的复杂性,让一些新手感到很困惑,因为开发者总是要从没有关联的位置中导入文件(`container`想要连接组件,反之亦然). 在我的使用经验汇总,从当个来源导入文件工作的更好一点.
   
因为我们在使用`styled-components`,所以可以删除掉`index.css`和`app.css`文件. 现在我们要在`src/styles`文件件中添加一些基础模板样式,创建文件`global.js`和`palette.js`文件

Palette包含了应用UI中使用的成组的颜色配置. 在`src/styles/palette.js`中添加

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyczobq16mj311s0m4t9v.jpg)


`global.js`用于生成应用中共享的基础样式. `styled-components`的`injectGlobal`方法应该要小心使用,但是用于应用级别的样式时时非常有用的.

**注意:** 在styled-components v4中`injectGlobal`已经被`createGlobalStyle`替代了.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyczryyv5ej30u00wn76b.jpg)

在`components`文件夹中创建`App`文件夹,把所有的 CRA默认生成的文件都移动到这个文件中,把`App.js`文件重命名为`index.js`文件. 这样就可以导入`components/App`

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyczua7grhj30fu0663yf.jpg)

现在代开`src/index.js`文件(项目的根文件),使用更新的文件结构更新文件.

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyczvc26p2j311s0hwwfk.jpg)

注意,因为之前我们定义了`NODE_PATH`,现在使用`components/App`导入`App`文件,`styles/globals`来导入`setGlobalStyles`文件. 执行`setGlobalStyles()`函数可以在应用中导入全局的样式.

现在我们已经准备好了启动应用开发环境的核心配置. 运行下面命令启动应用,会在`http://localhost:3000`看到应用. 现在看上去还不是太好,但是应用已经跑起来了 :)

```bash
yarn start
# npm 安装用 npm start

```

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd002pc2dj318g0ocaaq.jpg)


## 在 React 应用添加Redux

在`src/store`文件中,创建`index.js`,`reducer.js`和`middleware.js`文件. 让我们来初始化一个`app`专项(feature)来管理应用的state.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyd02i4w6jj30fm06a746.jpg)

以我的经验,在生产级别的应用中,如果按照特性而不是按照功能进行分组,Redux会更具有管理性,类似于[`鸭子方法`(Ducks approach)](https://medium.freecodecamp.org/scaling-your-redux-app-with-ducks-6115955638be). "按照功能分组(grouping by functionality)" 方法中所有的actions,reducers,等等都位于独立的文件夹中, 当应用规模增加时,在不同文件中切换难度就增大了. 如果按照特性分组,你需要的文件总是在一个位置.

在`index.js`文件中,创建`configureStore`函数,用于初始化应有的 Redux.

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyd0awnm8dj311s0gujse.jpg)

使用`createStore`构建初始化`store`. 从根reducer文件导入`reducer`,同时从middleware配置文件中导入 `middleware(中间件)`. `initialState` 应该在程序运行时提供,并传递给我们的函数. 在生产中,要能够管理复杂的功能例如 SSR(服务端渲染),或者在初始化时从服务器获取传递的数据. 在这里初始state,可以让我们更优雅的和抽象出store的创建过程.

在`reducer.js`文件中,使用`combineReducers`函数创建根reducer.此函数把所有的reducer函数组合起来生成单个的state树.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyd0ihkknwj311s0eqwf3.jpg)

接下来在`middleware.js`中创建中间件. 中间件是每一次dispatch action 时都必须要执行的函数. 中间在扩展Redux应用时非常有用. 在文件中添加如下代码

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fyd0l6d5ayj311s0m4dha.jpg)

也要构建第一个Reducer.在 `src/store/app`文件加中创建 `reducer.js`和`action.js`文件. 需要添加日间/夜间的切换模式功能,所以让我们创建一个action来管理这个特性.在`src/store/app/action.js` 添加下面代码

![](https://ws4.sinaimg.cn/large/006tNbRwly1fyd0q6sm3wj312m0hwdgn.jpg)

我们创建了一个`actionTypes`对象放置actio-type常量. 类似的常量在reducer中用于匹配改变state的类型. 也要创建`actions`对象,包含了可以从应用中`dispatch` 用于改变state的 action函数.每一个action都包括了一个`type`和一个`payload`(译注: type告诉store要干什么,payload 是执行action时携带的条件).


最后,创建我们的reducer

![](https://ws3.sinaimg.cn/large/006tNbRwly1fyd0vxeumqj311s0qcjsh.jpg)


当我们`dispatch`一个`SET_THEME` action时, 将会使用`payload`的内容更新 state中`theme`的属性值. `payload`是一个对象,形式是`{theme:'value'}`.使用es6的展开操作`...`,`state`中对应`payload`键的值会被替换掉.

如果需要详细理解 Redux的基础 ,看看[Dan Abramov的视频](https://egghead.io/courses/getting-started-with-redux) 

现在返回`src/index.js`文件,做一些更新,需要把我们的应用连接到 Redux. 为`Provider`添加一个导入,更新渲染方法

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd14i99i2j311s0re75s.jpg)

现在应该已经做完了 Redux的整个工作.返回到`localhost:3000`,在Chrome的console中可以看到下面的内容

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd15nfskwj30k2086dg6.jpg)


## 使用 React和Styld Components 构建 UI

现在 Redux 已经初始化完毕, 开始完成 UI 的工作. 首先声明一些会在应用中使用的样式常量. 在本应用中,我们要创建`mediaQueries(媒体查询)` 文件包含构建响应式应用的常量. 创建`src/styles/mediaQueries.js`文件,添加下面的代码

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyd192bwrhj311s09gq3m.jpg)

返回到`src/components/App`文件夹, 在`index.js`文件中,更新文件内容

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd1a56e2yj30zv0u0dhn.jpg)


其中使用了`styled-components`的`ThemeProvider`组件.这个组件尅让我们把"theme"作为`prop`传递给创建的styled components. 这里初始化theme为 `colorDark`对象.

`App`中包含的组件,现在还没有创建,所以现在来创建.首先构建styld-components 组件. 在`App`文件夹里创建`styles.js`文件, 添加代码

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fyd1eqcd23j31130u00uf.jpg)

创建的用于页面的`div`称为`Wrapper`. 用于页面标题的`h1`创建为`Title`组件. `styled-components`语法使用`styled`对象定义 HTML 元素. 可以用字符串定义组件的 CSS 属性.

注意代码20行, 我们使用了`theme` prop. 包含`props`参数的函数由`styled-components` 注入到样式字符串中,这么,我们就可提起属性或者添加用于动态构建样式的逻辑,从组件中抽象出构建样式的逻辑.

接下来, 创建包含 Hacker Nees故事的 `List` 组件. 创建`src/components/List`文件夹并添加`index.js`,`styles.js`文件. 在`index.js`文件中,添加代码

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyd1nwr1nmj311s0hw751.jpg)

在`styles.js`文件中创建`ListWrapper`.使用从`ThemeProvider`组件得到的`theme` props 的`background-color`属性.

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyd1py5vqmj311s0hwab3.jpg)


最后创建`ListItem`组件用于显示单个的故事. 创建`src/components/ListItem`文件夹和`index.js`,`styles.js`文件.

我们想让 UI模仿 Hacker News. 目前会在`ListItem`中使用fake 数据里模拟. 在`index.js`文件中添加代码

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd1taaq16j31070u0q5o.jpg)

每个故事都有标题,作者,评分,发帖时间,URL地址,评论数. 初始化这几个值,以便于查看 UI 的样子. 基于安全原因, 添加`rel="nofollow noreferrer noopener"`. 

在`styles.js`文件中添加下面代码

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fyd22e7zjrj30u01awgph.jpg)

这些应该就是我们需要的基础 UI 组件了. 返回到浏览器,应该看到使用fake数据的单个条目

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyd24hxbnaj318g06qq2x.jpg)

## 使用 Redux 和 Axios 构建 API 调用

是时候在应用添加实际数据了.我们通过`axios`库来调用 Hacker News的 API.调用 API 的过程会在应用中引入 "side effect(副作用)",意思是调用 API 会从外部资源影响本地环境的state.

API 调用之所以被称为 side effect,原因是在应用的state中引入了外部的数据. 其他的side effect的例子包括和浏览器的`localStorage`的交互操作, 追踪用户分析,连接到web socket,等等. 在 Redux 应用中可以使用很多库来管理 side effect. 从简单的[`redux-thunk`](https://github.com/reduxjs/redux-thunk) 到更为复杂的[`redux-saga`](https://github.com/redux-saga/redux-saga). 然而他们的目的是相同的,就是让 Redux与外界交互. `redux-thunk`是最简单的库, 可以在action `对象`中再次 `dispatch` JavaScript `函数`.
这个功能就是我们在使用`axios`时需要的功能,在 API调用管理返回的promise对象. 

在`src/services`文件夹中,创建`Api.js`和`hackerNewsApi.js`文件. `axios`库有着难以置信的强大功能和扩展性. `Api.js`包含的配置使得执行`axios`请求更容易. 这里没有拷贝完整代码,你可以在[`源代码`](https://github.com/gitconnected/hacker-news-reader/blob/master/src/services/Api.js)中看到信息内容,其中包含了更为精细的配置.

在`src/services/hackerNewsApi.js`文件中, 我们要定义请求 Hacker News API 的函数. 在[`Hacker New API 文档`](https://github.com/HackerNews/API) 可以找到,如果要获取 IDs 的列表, 要使用`/v0/topstories` 入口. 获取每个 id的独立故事要使用`/v0/items/<id>`  入口.  

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd2n70llcj318g0qutbp.jpg)

`v0/topstories` 入口返回列表中 IDs的 400-500条故事. 因为我们要获取单个故事的数据,如果立刻获取500个故事的数据会严重影响性能. 为了解决这个问题,我们一次只获取20个故事的数据. 使用`.slice()`函数基于页面的故事 ID进行分割. 因为我们使用`/v0/item/<id>` 调用每个故事的数据, 因此使用`Promise.all`把所有的请求返回的promise对象压缩的一个数组中,然后用一个`then()`,resolve返回获取数据,并且保存 IDs 的顺序标记.

为了在应用管理我们的故事state,我们来创建一个`story` reducer. 创建`src/store/story`文件夹, 添加`reducer.js`和`action.js`文件. 在`action.js`文件中添加代码

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd2wy2s1aj30u00zd79j.jpg)

为 IDs请求和stor用的API 调用都创建了 request,success,failure的 `actionTypes`. 

我们的`actions` 对象中包含了 用于请求管理的`thunk` 函数. 通过dispatch 函数而不是dispatch action 对象. 我们就可以在请求周期的不同点 dispatch 不同的acitons了.

函数`getTopStoryIds`会执行 API 调用,获取整个故事的列表. 在`getTopStoryIds`函数中success(成功)的回调函数执行时,我们会dispatch `fetchStories`  action,用于获取第一页故事的结果.

当 API 调用成功返回时,就可以dispatch  success Action,这样就可以使用新获取的数据来更新 Redux的 store了.

thunk软件包的基础实现只是用了几行代码. 要充分理解它,需要对 Redux的中间件有了解,但是从代码中,我们可以看到,如果我们使用一个`函数`来代替一个`对象`,就可以执行一个函数,并且把`dispatch`作为函数的参数传递.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyd38xped8j311s0ai0t5.jpg)

现在我们需要创建reducer用于 Redux store中的数据存储. 在`src/store/story/reudcer.js`中添加代码

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyd3aubj8rj30u00z6q5k.jpg)

对于 `FETCH_STORY_IDS_SUCCESS` action type,我们展开当前 state和 payload. 在 payload 中唯一的键/值是`storyIds`,展开操作将会用新的值来更新 state.

对于`FETCH_STORIES_SUCCESS` action type. 在之前的故事列表中按顺序添加故事,以便于获取更多的页面. 此外,增加page 数, 设置`isFetching` state 为false.

现在,State已经由 Redux管理了, 我们就可以在组件中显示数据了.

##  把React APP 连接到 Redux  Store

通过使用`react-redux`绑定,我们可以把组件连接到 Redux的store, 以props的形式接收Redux的 State.之后,只要 store 有更新,props就会引起组件的重新渲染,由此就更新了 UI.

在需要`dispatch`  action 的组件中,以 props 的形式传递函数. 之后在组件内部调用这些函数,就可以触发 Redux store 中的state变化.

来看看如何在应用中管理这个变化. 返回到`src/components/App`文件夹,创建一个 `App.js`文件, 从`src/components/App/index.js`拷贝内容进来. 在`index.js`文件里面,我们将会把`App`组件连接到 Redux. 在`index.js`文件中添加代码

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fyd3q01y3qj311s0qcdhk.jpg)

`mapStateToProps`函数接受 Redux `store`作为参数,返回一些属性到连接的组件中.对于`App`,我们需要 `stories` 数组, 当前页 `page`,`storyIds`数组还有`isFetching`指示器.

`mapDispatchToProps`函数接受`dispatch`函数作为参数,把返回的函数对象作为props传递给我们的组件.  创建的函数`fetchStoriesFirstPage`,执行时会`dispatch` action 来获取story IDs(然后获取第一页故事的内容).

我们在`App.js`中使用这两个props,首先添加`componentDidMount`,当组件在 DOM 中渲染完就可以立刻获取数据. 为`List`组件传递`stories` props.

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyd3ynyve9j311s0qcwfp.jpg)


在`src/components/List/index.js`中,遍历stories 数组, 创建 `ListItem`组件的数组. 设置列表的key为story ID,并且展开story对象: `...story`.展开操作会把对象的属性值作为单个的props传递给组件. `key` prop 是 React中组件作为数组加载时的一个策略,可以让列表形式的渲染更新速度更快.

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fyd42zdz6bj311s0dodgb.jpg)

如果现在观察屏幕,应该看到到的是硬编码的20行列表数据
![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd449n426j318g0ndjsj.jpg)

我们需要使用从stories 获取的数据对`ListItem`进行更新.同时在 Hacker News中, 也会显示上次故事更新的时间和来源的地址. 需要安装
[`timeago.js`](https://www.npmjs.com/package/timeago.js) 和[`URl`](https://www.npmjs.com/package/url) 软件包帮助计算没有通过 API 直接获取的数据, 使用下面命令执行安装

```bash
yarn add timeago.js url
```

需要编写助手函数来构建这些值. 从源码的`src/utils`文件夹中拷贝文件


现在更新 `src/components/ListItem/index.js`文件

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fyd4b31588j30u00v9gq4.jpg)


通过这一步, 现在就可以在应用显示前20个故事了- cool!

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyd4cp0h6wj318g0rbdhl.jpg)

## 使用无限滚动来对请求分页

现在,我们想实现的是当用于页面滚动到底部, 获取新的一页.回忆一下,每次成功获取故事之后,我们都增加了store中page的数字. 所以在第一页到达之后,Redux store 现在应该是`page:1`.我们需要在滚动到底部时`dispatch` `fetchStories` action.

为了实现无限滚动,我们会使用`react-infinite-scroll-component`组件. 我们也想实现一个方法来决定管是否要加载更多的页面,这一点我们使用[`reselect`](https://www.npmjs.com/package/reselect) 在selector中实现.

```bash
yarn add react-infinite-scroll-component reselect
```

首先构建selector来计算是否有更多的故事存在. 创建 `src/store/story/selecor.js`文件. 为了判断是否有更多故事存在, 我们 Redux store中的`storyIds` 数组的长度是否和`stories`的长度相同, 如果`stories`的长度短一点,意思就是有更多的页面存在

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fydcy308sxj311s0guaba.jpg)

在`src/components/App/index.js` container中,导入`hasMoreStoriesSelector` 在`mapStateToProps`中添加 键`hasMoreStories`.同时在`mapDispatchProps`中添加`fetchStories` action,便于滚动时 dispatch action.

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fydd2kyrcrj318g0hkmyb.jpg)

我们想在等待 API请求时使用动画显示. 创建`src/components/Loader`文件夹,`index.js`和`styles.js`文件. 需要的动画是闪动的三个圆点.

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fydd4v04ajj308401w0mz.jpg)

在`styles.js`文件中添加下面代码

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fydd5q30w3j30u01awq6e.jpg)

@keyframe 是定义动画的 CSS 技术. 上面代码显示了在 Styled Components中的代码抽象. 有三个圆点,透明度从0.2开始增加到1, 然后返回到0.2, 给第二个和第三个点添加延迟,表现出弹跳式的偏移.

我们的`Loader`组件就是有三个独立span元素的动画styled components动画组件.

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyddal78evj311s0hwwf2.jpg)

现在,准备为列表添加功能,在`App`组件中导入无限加载模块和`Loader`组件.也要创建`fetchStories`回调函数,将会调用`fetchStories` prop  dispatch 下一页的action. 只有在`isFetching`为 false 时dispatch `fetchStories` action. 如果为 true.我们就多次获取统一页面. 你的`src/components/App/App.js`文件应该如下

![](https://ws2.sinaimg.cn/large/006tNbRwgy1fyddfxb91ej30u0198dk2.jpg)


当我们滚动到页面底部, 只要`hasMoreStories`为真,`InfiniteScroll`组件将会调用`this.fetchStroies`. 当fetchStories API 请求返回时,新的故事会添加到`stories`数组的尾部,渲染到页面中.

## 最后的挑战

在教程刚开始, 我们初始化了一个`theme` property.现在,留给你实现一个toggle功能. 在一些组件中添加点击事件,dispatch `setTheme` action.切换 `light`和`dark`的状态. 在`ThemeProvider`组件中需要一个三元条件判断如果 `state.app.theme==='dark'`就传递`colorDark`,否则就传递`colorsLight`.

如果你卡住了,可以看看源码的实现.加入[Slack](https://community.gitconnected.com/) 寻求帮助. 试试我们的办法.

## 部署到GitHub 主页

对于应用的最后一步都是投入生产. 因为我们的功能是在客户端,可以免费部署在 GitHub 主页的静态网站.

提交你的代码并推送到Github. 我命名仓库为`hn-clone`.如果你在创建仓库和上传代码是遇到问题可以参照一下[`这个指导`](https://help.github.com/articles/adding-an-existing-project-to-github-using-the-command-line/) 

现在使用如下的步骤发送过的 GitHub 主页:
1. 在package.json文件中添加 `"homepage":"http://<username>.github.io/<repo-name>"` 使用你的实际值替换`<username>`和`<repo-name>`. 我的值是 `treyhuffine`和`hn-clone`.

![](https://ws4.sinaimg.cn/large/006tNbRwgy1fyddue4bz1j30mg02m3yj.jpg)

2. 安装`gh-pages`作为开发依赖项

```bash
yarn add -D gh-pages
```

3. 在`package`.json文件中添加两个脚本

```bash
"predeploy": "npm run build","deploy": "gh-pages -d build"
```

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyddw03vwij30gi0akdga.jpg)


4. 最后运行`yarn deploy` 并访问在homepage中定义的URL.

![](https://ws1.sinaimg.cn/large/006tNbRwgy1fyddx4ikxaj30is01eq2s.jpg)

现在你的 Hacker News 投入生产了. 

## 结论

本文覆盖了构建 Hacker News clone所必须的所有的功能. 源码还有一些额外的特性,持续更新中,  查看一下是否有灵感出现可以继续添加功能,学习更多的 React 知识.

不要忘了下载Chrome 扩展, 并访问 gitconnectec.com网站,加入开发者社区.


原文发表在 [gitconnected.com-开发者社区](https://gitconnected.com/courses/learn-react-redux-tutorial-build-a-hacker-news-clone)
