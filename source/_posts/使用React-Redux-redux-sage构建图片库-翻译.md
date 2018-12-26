---
title: 使用React,Redux,redux-sage构建图片库(翻译)
date: 2017-04-04 13:18:28
categories: 翻译
tags: [Redux,saga]
---

>看到这篇文章[build an image gallery using redux saga](http://joelhooks.com/blog/2016/03/20/build-an-image-gallery-using-redux-saga/)，觉得写的不错，长短也适中.  文后有[注释版的github代码库,请使用comment分枝](https://github.com/phpsmarter/egghead-react-redux-image-gallery/tree/comment). Flickr API可能需要有fQ的基本能力.可以使用google的翻译作为参考，这篇文章google翻译版的中文水平让我吃了一惊.
翻译已经完成.

___

### 使用React,Redux和reudx-saga构建一个图像浏览程序(翻译)
Joel Hooks ,2016年3月

##### 构建一个图片长廊

图像长廊是一个简单的程序，从Flicker API 加载图片URLs,允许用户查看图片详情。


![Screen Shot 2016-03-20 at 3.42.17 PM-2.png](http://upload-images.jianshu.io/upload_images/2044710-b0d03ac095f09c55.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/240)



后续我们会使用React,Redux和redux-saga.React作为核心框架，优势是虚拟dom(virtual-dom)的实现。Redux在程序内负责state的管理。最后，我们会使用redux-saga来执行javascript的异步操作步骤。

我们会使用ES6(箭头函数，模块，和模板字符串)，所以我们首先需要做一些项目的配置工作。

#####项目配置和自动化
___
如果要开始一个React项目，须有有一系列的配置选项。对于一个简单的项目，我想把配置选项尽可能缩减。考虑到浏览器的版本问题，使用Babel把ES6编译为ES5。

首先使用npm init 创建一个`package.json`文件

package.json

```javascript
  {
  "name": "egghead-react-redux-image-gallery",
  "version": "0.0.1",
  "description": "Redux Saga beginner tutorial",
  "main": "src/main.js",
  "scripts": {
    "test": "babel-node ./src/saga.spec.js | tap-spec",
    "start": "budo ./src/main.js:build.js --dir ./src --verbose  --live -- -t babelify"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/joelhooks/egghead-react-redux-image-gallery.git"
  },
  "author": "Joel Hooks <joelhooks@gmail.com>",
  "license": "MIT",
  "dependencies": {
    "babel-polyfill": "6.3.14",
    "react": "^0.14.3",
    "react-dom": "^0.14.3",
    "react-redux": "^4.4.1",
    "redux": "^3.3.1",
    "redux-saga": "^0.8.0"
  },
  "devDependencies": {
    "babel-cli": "^6.1.18",
    "babel-core": "6.4.0",
    "babel-preset-es2015": "^6.1.18",
    "babel-preset-react": "^6.1.18",
    "babel-preset-stage-2": "^6.1.18",
    "babelify": "^7.2.0",
    "browserify": "^13.0.0",
    "budo": "^8.0.4",
    "tap-spec": "^4.1.1",
    "tape": "^4.2.2"
  }
}
```
___

 有了`package.json`, 可以在项目文件夹命令行运行 `npm install` 安装程序需要的依赖项。
 
 .babelrc

```
{
  "presets": ["es2015", "react", "stage-2"]
   } 
```
       
       
这个文件告诉babel,我们将会使用ES2015(ES6),React以及ES2106的stage-2的一些特征。

`package.json`有两个标准的script脚本配置：`start`和`test`.现在我们想通过start脚本加载程序，start会使用`src`目录的一些文件，所以西药先创建`src`文件夹.在`src`文件夹添加下面的一些文：

`index.html`

```
   <!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>egghead: React Redux Image Gallery</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
<div class="title">
  ![](http://cloud.egghead.io/2G021h3t2K10/download/egghead-logo-head-only.svg)
  <h3>Egghead Image Gallery</h3>
</div>

<div id="root"></div>

<script type="text/javascript" src="build.js"></script>
</body>
</html>
 
```
    
    
 


`main.js`


```
import "babel-polyfill"

import React from 'react'
import ReactDOM from 'react-dom'

ReactDOM.render(
  <h1>Hello React!</h1>,
  document.getElementById('root')
);
```


`style.css`

```
    body {
    font-family: Helvetica, Arial, Sans-Serif, sans-serif;
    background: white;
}

.title {
    display: flex;
    padding: 2px;
}

.egghead {
    width: 30px;
    padding: 5px;
}

.image-gallery {
    width: 300px;
    display: flex;
    flex-direction: column;
    border: 1px solid darkgray;
}

.gallery-image {
    height: 250px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.gallery-image img {
    width: 100%;
    max-height: 250px;
}

.image-scroller {
    display: flex;
    justify-content: space-around;
    overflow: auto;
    overflow-y: hidden;
}

.image-scroller img {
    width: 50px;
    height: 50px;
    padding: 1px;
    border: 1px solid black;
}

```


`index.html`文件加载`style.css`文件提供一些基本的布局样式，同时也加载`build.js`文件，这是一个生成出来的文件.`main.js`是一个最基础的React程序，他在`index.html`的`#root`元素中渲染一个`h1`元素。创建这些文件以后，在项目文件夹中命令行运行`npm start`。在浏览器打开`http://10.11.12.1:9966`.就可以看到`index.html`中渲染的页面

![运行加载图](http://upload-images.jianshu.io/upload_images/2044710-b24265cbe5f89d88.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/240)


现在我们来构建基础的`Gallery` React 组件

##### 在Gallery中显示一些图片

 首先我们需要尽可能快的获得一个可以显示的图片素材.在项目文件夹中创建一个文件`Gallery.js`
 
 `Gallery.js`
  
```
    import React, {Component} from 'react'

const flickrImages = [
  "https://farm2.staticflickr.com/1553/25266806624_fdd55cecbc.jpg",
  "https://farm2.staticflickr.com/1581/25283151224_50f8da511e.jpg",
  "https://farm2.staticflickr.com/1653/25265109363_f204ea7b54.jpg",
  "https://farm2.staticflickr.com/1571/25911417225_a74c8041b0.jpg",
  "https://farm2.staticflickr.com/1450/25888412766_44745cbca3.jpg"
];

export default class Gallery extends Component {
  constructor(props) {
    super(props);
    this.state = {
      images: flickrImages,
      selectedImage: flickrImages[0]
    }
  }
  render() {
    const {images, selectedImage} = this.state;
    return (
      <div className="image-gallery">
        <div className="gallery-image">
          <div>
            <img src={selectedImage} />
          </div>
        </div>
        <div className="image-scroller">
          {images.map((image, index) => (
            <div key={index}>
              <img src={image}/>
            </div>
          ))}
        </div>
      </div>
    )
  }
}
```
  

  我们直接在组件中硬编码了一个提供数据的数组，让项目尽快的工作起来.`Gallery组件`继承`Component组件`,在构造函数中创建一些组件的出事状态.最后我们利用一些样式标记渲染一下文件。`image-scroller`元素遍历(`map`方法)图片数组,生成摘要小图片。
  
```
    import "babel-polyfill"

import React from 'react'
import ReactDOM from 'react-dom'

+ import Gallery from './Gallery'

ReactDOM.render(
-  <h1>Hello React!</h1>,
+  <Gallery />,
  document.getElementById('root')
);
```
  
  到现在，我们使用硬编码的图片URLs(通过fickrImages)数组,第一张图片作为`selectedImage`.这些属性在`Gallery`组件的构造函数缺省配置中，通过初始状态(initial)来设定.

  
  接下来在组件中添加一个和组件进行交互操作的方法，方法具体内容是操做`setSate`.
  Gallery.js
  
```
export default class Gallery extends Component {
  constructor(props) {
    super(props);
    this.state = {
      images: flickrImages,
      selectedImage: flickrImages[0]
    }
  }
+  handleThumbClick(selectedImage) {
+    this.setState({
+      selectedImage
+   })
+  }
  render() {
    const {images, selectedImage} = this.state;
    return (
      <div className="image-gallery">
        <div className="gallery-image">
          <div>
            <img src={selectedImage} />
          </div>
        </div>
        <div className="image-scroller">
          {images.map((image, index) => (
-            <div key={index}>
+            <div key={index} onClick={this.handleThumbClick.bind(this,image)}>
              <img src={image}/>
            </div>
          ))}
        </div>
      </div>
    )
  }
}
```

在`Gallery组件`添加`handleThumbClick`方法,任何元素都可用通过`onClick`属性调用这个方法.`image`作为第二个参数传递，元素自身作为第一个参数传递.bind方法传递javascript函数调用上下文对象是非常便捷。

看起来不错!现在我们有了一些交互操作的方法，有点“APP”的意思了。截止目前，我们已经让app运行起来了，接下来要考虑怎么加载远程数据。最容易加载远程数据的地方是一个`React组件`生命周期方法,我们使用`componentDidMount`方法,通过他从`Flikr API`请求并加载一些图片.

`Gallery.js`
 
```
   export default class Gallery extends Component {
  constructor(props) {
    super(props);
    this.state = {
      images: flickrImages,
      selectedImage: flickrImages[0]
    }
  }
+  componentDidMount() {
+    const API_KEY = 'a46a979f39c49975dbdd23b378e6d3d5';
+    const API_ENDPOINT = `https://api.flickr.com/services/rest/?method=flickr.interestingness.+getList&api_key=${API_KEY}&format=json&nojsoncallback=1&per_page=5`;+
+
+    fetch(API_ENDPOINT).then((response) => {
+      return response.json().then((json) => {
+        const images = json.photos.photo.map(({farm, server, id, secret}) => { 
+            return `https://farm${farm}.staticflickr.com/${server}/${id}_${secret}.jpg`
+        });
+
+        this.setState({images, selectedImage: images[0]});
+      })
+    })
+  }
[...]
```

我们在`Gallery`类中添加了一个新的方法,通过React的`componentDidMount`生命周期方法触发Flickr图片数据的获取。

在`React`组件运行的不同时间点，组件会调用不同的生命周期函数。在这段代码中，当组件被渲染到`DOM`中的时间点,`componentDidMount`函数就会被调用。需要注意的是:`Gallery`组件只有一次渲染到`DOM`的机会，所以这个函数可以提供一些初始化图片.考虑到在APP的整个生命周期中,有更多的动态组件的加载和卸载,这可能会造成一些多余的调用和无法考虑到的结果。

我们使用浏览器接口(browser API)的`fetch`方法执行请求.Fetch返回一个promise对象解析`response`对象.调用`response.json()`方法,返回另一个promise对象，这就是我们实际需要的`json`格式的数据.遍历这个对象以后就可以获取图片的url地址.

>坦白讲，这个应用目前还很简单.我们还需要在这里花费更多的时间，还有一些基础的需求需要完成.或许我们应该在promise处理流程中添加错误处理方法,如果图片数据获取成功也需要一些处理逻辑.在这个地方，你需要发挥一些想象力考虑一下更多的逻辑.在生产实践中简单的需求是很少见的.很快,应用中就会添加更多的需求。认证,滚动橱窗,加载不同图片库的能力和图片的设置等等.仅仅这些还远远不够.

我们已经使用`React`构建了一个加载图片库的程序。接下来我们需要考虑到随着程序功能的添加，到底需要哪些基础的模式.首先考虑到的一个问题就是要把应用的状态(state)控制从`Gallery`组件中分离出来.

我们通过引入`Redux`来完成应用的状态管理工作。

##### 使用`Redux`来管理状态

在你的应用中只要使用了`setState`方法都会让一个组件从无状态变为有状态的组件.糟糕的是这个方法会导致应用中出现一些令人困惑的代码,这些代码会在应用中到处蔓延。

`Flux`构架来减轻这个问题.`Flux`把逻辑(logic)和状态(state)迁移到`Store`中.应用中的动作(`Actions`)被`Dispatch`的时候,`Stores`
会做相应的更新.`Stores`的更新会触发`View`根据新状态的渲染.

那么我们为什么要舍弃`Flux`?他竟然还是“官方”构建的.
好吧！`Redux`是基于`Flux`构架的,但是他有一些独特的优势.下面是Dan Abramov(Redux创建者)的一些话：
>Redux和Flux没有什么不同.总体来讲他们是相同的构架,但是Redux通过功能组合把Flux使用回调注册的复杂点给屏蔽掉了.
两个构架从更本上讲没有什么不同，但是我发现Redux使一些在Flux比较难实现的逻辑更容易实现.


[Redux文档](http://cn.redux.js.org/index.html)非常棒.
如果你还没有读过代码的卡通教程或者Dan的系列文章.赶快去看看吧！

##### 启动Redux

第一件需要做的事事初始化`Redux`,让他在我们的程序中运行起来.现在不需要做安装工作，刚开始运行`npm install`的时候已经安装好了依赖项，我们需要做一些导入和配置工作.
**reducer函数是Redux的大脑.** 每当应用分发(或派遣,dispatch)一个操作(action)的时候,`reducer`函数会接受操作(action)并且依据这个动作(action)创建`reducer`自己的`state`.因为`reducers`是纯函数，他们可以组合到一起，创建应用的`一个完整state`.让我们在`src`中创建一个简单的reducer:

`reducer.js`
 
```
   export default function images(state, action) {
      console.log(state, action)
      return state;
   }
```

 一个reducer函数接受两个参数(arguments).
   1. [x] `state`-这个数据代表应用的状态(state).reducer函数使用这个状态来构建一个reducer自己可以管理的状态.如果状态没有发生改变,reducer会返回输入的状态.
   2. [x]  `action`-这是触发reducer的事件.Actions通过store派发(dispatch),由reducer处理.action需要一个`type`属性来告诉reducer怎么处理state.

目前,`images` reuducer在终端中打印出日志记录，表明工作流程是正常的，可以做接下来的工作了.为了使用reducer，需要在`main.js`中做一些配置工作:

`main.js`

```
import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';

import Gallery from './Gallery';

+ import { createStore } from 'redux'
+ import reducer from './reducer'

+ const store = createStore(reducer);

+ import {Provider} from 'react-redux';

ReactDOM.render(
+  <Provider store={store}>
    <Gallery />
+  </Provider>,
  document.getElementById('root')
);
}
```

 
 我们从`Redux`库中导入`createStore`组件.`creatStore`用来创建Redux的store.大多数情况下,我们不会和store直接交互,store在Redux中做幕后管理工作.

 也需要导入刚才创建的reducer函数,以便于他可以被发送到store.
 我们将通过`createStore(reducer)`操作，利用reducer来配置应用的store.这个示例仅仅只有一个reducer,但是`createStore`可以接收多个reducer作为参数.稍后我们会看到这一点.
 
 最后我们导入高度集成化的组件`Provider`,这个组件用来包装`Gallery`,以便于我们在应用中使用Redux.我们需要把刚刚创建的store传递给`Provider`.你也可以不使用`Provider`,实际上Redux可以不需要React.但是我们将会使用`Provider`,因为他非常便于使用.
 
 

![打印日志](http://upload-images.jianshu.io/upload_images/2044710-6667a047b669d287.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/320)

 这张图可能有点古怪，但是展示了Redux的一个有意思的地方.所有的reducers接收在应用中的全部actions(动作或操作).在这个例子中我们可以看到Redux自己派发的一个`action`.
##### 连接Gallery组件
 
 借助Redux,我们将使用”connected”和“un-connected”组件.一个`connected`组件被连线到store.`connected`组件使控制动作事件(controls action event)和store协作起来.通常,一个`connected`组件有子组件,子组件具有单纯的接收输入和渲染功能，当数据更新时执行调用.这个子组件就是unconnected组件.
 >提示:当Rect和Redux配合是工作的非常好,但是Redux不是非要和React在一起才能工作.没有React,Redux其实可以和其他框架配合使用.
 
 
在应用中需要关联`React组件`和`Redux Store` 的时候，`react-redux`提供了便捷的包装器.我们把react-redux添加进`Gallery`中
,从而使`Gallery`成为首要的关联组件.

`Gallery.js`
```
  import React, {Component} from 'react'
+import {connect} from 'react-redux';

-export default class Gallery extends Component {
+export class Gallery extends Component {
  constructor(props) {
    super(props);
+    console.log(props);
    this.state = {
      images: []
    }
  }
  componentDidMount() {
    const API_KEY = 'a46a979f39c49975dbdd23b378e6d3d5';
    const API_ENDPOINT = `https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=${API_KEY}&format=json&nojsoncallback=1&per_page=5`;

    fetch(API_ENDPOINT).then((response) => {
      return response.json().then((json) => {
        const images = json.photos.photo.map(({farm, server, id, secret}) => {
            return `https://farm${farm}.staticflickr.com/${server}/${id}_${secret}.jpg`
        });

        this.setState({images, selectedImage: images[0]});
      })
    })
  }
  handleThumbClick(selectedImage) {
    this.setState({
      selectedImage
    })
  }
  render() {
    const {images, selectedImage} = this.state;
    return (
      <div className="image-gallery">
        <div className="gallery-image">
          <div>
            <img src={selectedImage} />
          </div>
        </div>
        <div className="image-scroller">
          {images.map((image, index) => (
            <div key={index} onClick={this.handleThumbClick.bind(this,image)}>
              <img src={image}/>
            </div>
          ))}
        </div>
      </div>
    )
  }
}

+export default connect()(Gallery)
```

从`react-redux`导入`connect`函数,可以在导出组件的时候把他变为链接组件(connected component).请注意,`connect()(Gallery)`代码把`Gallery`组件放在第二个形参中,这是因为`connect()`返回一个函数，这个函数接受一个React组件作为参数(argument).调用`connect()`函数时需要配置项.后面我们将会传递配置我们应用的actions和state参数.
我们也把`connect`作为默认配置到处模块.这一点非常重要！现在当我们`import Gallery`的时候,就不是一个单纯的React组件了,而是一个和Redux关联的组件了.



![](http://upload-images.jianshu.io/upload_images/2044710-72a9136f9b481bf6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/620)

如果你观察我们添加进构造器的`console.log`的输出,就可以看到`Gallery`组件的属性现在包括了一个`dispatch`函数.这个地方是`connect`为我们的应用修改的,这个改动赋予了组件把自己的动作对象(action objects)`派发`到`reducers`的能力.

```
    export class Gallery extends Component {
  constructor(props) {
    super(props);
+    this.props.dispatch({type: 'TEST'});
    this.state = {
      images: []
    }
  }
[...]
```

我们可以在组件的构造器中调用派发功能.你可以在开发者的终端中看到来自reducer的日志声明.看到声明表示我们已经派发了第一个action!.Actions是一个单一的javascript对象,必需有`type`属性.Actions可以拥有任意数量和种类的其他属性.但是`type`可以让reducers理解这些动作到底是做什么用的(意译，意思是只有拥有type属性，reducers才知道对state做什么样的修改).

```
export default function images(state, action) {
-  console.log(state, action)
+  switch(action.type) {
+    case 'TEST':
+      console.log('THIS IS ONLY A TEST')
+  }
  return state;
}
```
 
 
 总的reducers使用`switch代码块`过滤有关的消息,`Switch`语句使用actions的type属性,当一个`action`和`case`分支吻合以后,相应的单个reducer就会执行他的具体工作.
 
 我们的应用现在关联到接收的动作.现在我们需要把`Redux`-`Store`提供的`state`关联到应用中.
 
#### 默认的应用状态(state)
 `reducer.js`
```
  const defaultState = {
  images: []
}

export default function images(state = defaultState, action) {
  switch(action.type) {
    case 'TEST':
-      console.log('THIS IS ONLY A TEST')
+      console.log(state, action)
+      return state;
+    default:
+      return state;
  }
-  return state;
}
 
```
 
 我们创建一个`defaultState`对象,这个对象返回一个空数组作为images的属性.我们把`images`函数的参数`state`设置为默认.如果在test分支中输出日志,将会看到state不是undefined(空数组不是undefined)!reducer需要返回应用的当前state.这点很重要!现在我们没有做任何改变,所以仅仅返回state.注意我们在`case`中添加了default分支,reducer必须要返回一个state.
 
在`Gallery`组件中，我们也可以把state做一定的映射(map)以后再连接到应用.
 
```
  import React, {Component} from 'react'
import {connect} from 'react-redux';

export class Gallery extends Component {
  constructor(props) {
    super(props);
    this.props.dispatch({type: 'TEST'});
+    console.log(props);
-    this.state = {
-      images: []
-    }
  }
-  componentDidMount() {
-    const API_KEY = 'a46a979f39c49975dbdd23b378e6d3d5';
-    const API_ENDPOINT = `https://api.flickr.com/services/rest/?method=flickr.interestingness.-getList&api_key=${API_KEY}&format=json&nojsoncallback=1&per_page=5`;-
-
-    fetch(API_ENDPOINT).then((response) => {
-      return response.json().then((json) => {
-        const images = json.photos.photo.map(({farm, server, id, secret}) => { 
-            return `https://farm${farm}.staticflickr.com/${server}/${id}_${secret}.jpg`
-        });
-
-        this.setState({images, selectedImage: images[0]});
-      })
-    })
-  }
-  handleThumbClick(selectedImage) {
-    this.setState({
-      selectedImage
-    })
-  }
  render() {
-    const {images, selectedImage} = this.state;
+    const {images, selectedImage} = this.props;
    return (
      <div className="image-gallery">
        <div className="gallery-image">
          <div>
            <img src={selectedImage} />
          </div>
        </div>
        <div className="image-scroller">
          {images.map((image, index) => (
-            <div key={index} onClick={this.handleThumbClick.bind(this,image)}>
+            <div key={index}>
              <img src={image}/>
            </div>
          ))}
        </div>
      </div>
    )
  }
}

+function mapStateToProps(state) {
+  return {
+    images: state.images
+    selectedImage: state.selectedImage
+  }
+}

-export default connect()(Gallery)
+export default connect(mapStateToProps)(Gallery)

``` 
  
  我们将移除连接组件中的所有图片加载和交互逻辑代码,如果你注意看`Gallery`组件的底部代码,你会注意到，我们创建了一个`mapStateToProps`函数,接收一个`state`作为参数,返回一个对象,把`state.images`映射为`images`属性.`mapStateToProps`做为参数传递给`connect`.
  正如名字暗示的一样,`mapStateToProps`函数接收当前应用的state,然后把state转变为组件的属性(propertys).如果在构造器中输出props,将会看到images数组是`reducer`返回的默认state.
  
```
   const defaultState = {
-  images: []
+  images: [
+    "https://farm2.staticflickr.com/1553/25266806624_fdd55cecbc.jpg",
+    "https://farm2.staticflickr.com/1581/25283151224_50f8da511e.jpg",
+    "https://farm2.staticflickr.com/1653/25265109363_f204ea7b54.jpg",
+    "https://farm2.staticflickr.com/1571/25911417225_a74c8041b0.jpg",
+    "https://farm2.staticflickr.com/1450/25888412766_44745cbca3.jpg"
+  ],
+  selectedImage: "https://farm2.staticflickr.com/1553/25266806624_fdd55cecbc.jpg"
}

export default function images(state = defaultState, action) {
  switch(action.type) {
    case 'TEST':
      console.log(state, action)
      return state;
    default:
      return state;
  }
}
```

  
  如果在`defaultState`中更新images数组,你将可以看到一些图片重新出现在gallery中!现在当用户点击缩略图的时候,我们可以反馈选择动作,返回对应的大图.
  
#### 更新state
  怎么操作才能根据新选择的图片更新state?
  需要配置reducer监听`IMAGE_SELECTED`动作,借助action携带的信息(payload,有的文章翻译为载荷,载荷怎么理解？手机载荷就是声音，短信和流量数据。如果是卡车就是拉的货物,如果是客车就乘载的乘客,action的载荷就是要让reducer明白你要干什么，需要什么)来更新state.
```
  const defaultState = {
  images: [
    "https://farm2.staticflickr.com/1553/25266806624_fdd55cecbc.jpg",
    "https://farm2.staticflickr.com/1581/25283151224_50f8da511e.jpg",
    "https://farm2.staticflickr.com/1653/25265109363_f204ea7b54.jpg",
    "https://farm2.staticflickr.com/1571/25911417225_a74c8041b0.jpg",
    "https://farm2.staticflickr.com/1450/25888412766_44745cbca3.jpg"
  ],
  selectedImage: "https://farm2.staticflickr.com/1553/25266806624_fdd55cecbc.jpg"
}

export default function images(state = defaultState, action) {
  switch(action.type) {
-    case 'TEST':
    case 'IMAGE_SELECTED':
-      return state;
+      return {...state, selectedImage: action.image};
    default:
      return state;
  }
}
```
  
  现在reducer已经准备接收`IMAGE_SELECTED` action了.在`IMAGE_SELECTED`分支选项内,我们在展开(spreading,ES6的对象操作方法),并重写`selectedImage`属性后,返回一个新state对象.了解更多的`...state`对象操作可以看`ruanyifeng`的书.
  
```
   import React, {Component} from 'react'
import {connect} from 'react-redux';

export class Gallery extends Component {
-  constructor(props) {
-    super(props);
-    this.props.dispatch({type: 'TEST'});
-    console.log(props);
-  }
  render() {
-    const {images, selectedImage} = this.props;
+    const {images, selectedImage, dispatch} = this.props;

    return (
      <div className="image-gallery">
        <div className="gallery-image">
          <div>
            <img src={selectedImage} />
          </div>
        </div>
        <div className="image-scroller">
          {images.map((image, index) => (
-            <div key={index}>
+            <div key={index} onClick={() => dispatch({type:'IMAGE_SELECTED', image})}>
              <img src={image}/>
            </div>
          ))}
        </div>
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    images: state.images,
    selectedImage: state.selectedImage
  }
}

export default connect(mapStateToProps)(Gallery)
```

  在`Gallery`组件中,我们将会在组件的属性中定义`dispatch`在`onClick`函数体中调用他,现在我们从便利角度考虑把他们放在一起,但是两者功能是一样的.一旦我们点击了缩略图,他将会通过reducer更新大图.
 使用dispatch可以很方便的创建通用actions,但是很快我们会需要重用命名好的actions.为了这样做,可以使用”action creators”.
 
#### Action Creators
 Action creators函数返回配置好的action对象.我们在`action.js`中添加第一个action creator.
 
 `action.js`
```
 export const IMAGE_SELECTED = 'IMAGE_SELECTED';

export function selectImage(image) {
  return {
    type: IMAGE_SELECTED,
    image
  }
}
``` 

 这个方法经过export以后,可以直接在任何需要创建`selectImage` action地方导入!`selectImage`是纯函数，只能返回数据.他接收一个image作为参数,把image添加到action对象中，并返回.
 
 >注意:我们正在返回一个单纯的javascript object,但是`image`的属性可能很古怪，如果你以前没有碰到这样的样式.从ES6的角度出发,如果你给一个对象传递一个类似这样的属性,隐含的意思是把`image:'任何image包含的值'`添加到最终返回的对象.超级好用!
 
```
 import  * as GalleryActions from './actions.js';
[...]
onClick={() => dispatch(GalleryActions.selectImage(image))}
```

 this isn’t much than just using `dispatch` though.
 
 幸运的是,这个模式很普遍,Redux在`bindActionCreators`函数里提供了一个更好的办法来完成这个功能.
 
```
 import React, {Component} from 'react'
import {connect} from 'react-redux';
+ import {bindActionCreators} from 'redux';

+ import  * as GalleryActions from './actions.js';

export class Gallery extends Component {
  constructor(props) {
    super(props);
    this.props.dispatch({type: 'TEST'});
    console.log(props);
  }
  handleThumbClick(selectedImage) {
    this.setState({
      selectedImage
    })
  }
  render() {
-    const {images, selectedImage, dispatch} = this.props;
+    const {images, selectedImage, selectImage} = this.props;
    return (
      <div className="image-gallery">
        <div className="gallery-image">
          <div>
            <img src={selectedImage} />
          </div>
        </div>
        <div className="image-scroller">
          {images.map((image, index) => (
-            <div key={index} onClick={() => dispatch({type:'IMAGE_SELECTED', image})}>
+            <div key={index} onClick={() => selectImage(image)}>
              <img src={image}/>
            </div>
          ))}
        </div>
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    images: state.images,
    selectedImage: state.selectedImage
  }
}

+function mapActionCreatorsToProps(dispatch) {
+  return bindActionCreators(GalleryActions, dispatch);
+}

-export default connect(mapStateToProps)(Gallery)
+export default connect(mapStateToProps, mapActionCreatorsToProps)(Gallery)
```
 
 我们已经添加了`mapActionCreatorsToProps`函数,他接收`dispatch`函数作为参数.返回`bindActionCreators`的调用结果,`GalleryActions`作为`bindActionCreators`的参数.现在如果你输出属性日志,就看不到`dispatch`作为参数,`selectImage`直接可以使用了.(这里相当于对dispatch和action进行了包装).
 
 现在回顾一下,我们做了几件事:
 - 创建了一个reducer包含应用的默认初始状态(initial state),并且监听actions的执行.
 - 创建了一个store,把reducer具体化,提供一个分发器(dispatcher)可以分发action.
 - 把我们的Gallery组件关联到store的state.
 - 把store的state映射为属性(property)，传递给Gallery.
 - 映射一个动作创建器,Gallery可以简单的调用`selectImage(image)`,分发动作,应用状态将会更新.



那么，我们怎么才能使用这些模式从远程资源加载数据呢？

这个过程将会非常有趣!

#### 异步活动？


你可能在参加函数式编程的时候听说过”副作用”(side effects)这个名词,side effects是发生在应用的范围之外的东西.在我们舒适的肥皂泡里,side effect根本不是问题,但是当我们要到达一个远程资源,肥皂泡就被穿透了.有些事情我们就控制不了了,我们必须接受这个事实.(根据这段话，side effect 翻译为意想不到的事情，出乎意料的不受控制的事情更好)

在Redux里,reducer没有Side effects.这意味着reducers不处理我们应用中的异步活动.我们不能使用reducers加载远程数据,因为reducers是纯函数,没有side effects.

Redux很棒,如果你的应用里没有任何异步活动，你可以停下来,不用再往下看了.
如果你创建的应用比较大,可能你会从服务端加载数据,这时,当然要使用异步方式.

>**注意**： Redux其中一个最酷的地方是他非常小巧.他试图解决有限范围内的问题.大多数的应用需要解决很多问题!万幸,Reduc提供中间件概念,中间件存在于action->reducer->store的三角关系中,通过中间件的方式,可以导入诸如远程数据异步加载类似的功能.


其中一个方法是使用`thunks`对象,在Redux中有 redux-thunk 中间件.Thunks非常厉害，但是可能会导致actions的序列很复杂,测试起来也是很大的挑战.

考虑到我们的 图片浏览程序.当应用加载是,需要做:
- 从服务器请求图片数组
- 当图片加载完毕,显示提示消息
- 当远程数据返回以后,选择初始图片显示
- 处理可能出现的错误



这些事件都要在用户点击应用里的任何元素之前完成!
我们该怎么做呢？
redux-saga就是为此而诞生,为我们的应用提供绝佳的服务.

redux-sage

redux-sage可以在Redux应用中操作异步actions.他提供中间件和趁手的方法使构建复杂的异步操作流程轻而易举.

一个saga是一个Generator(生成器),Generator函数是ES2015新添加的特性.可能是你第一次遇到Generator函数,这样你会觉得有点古怪,可以参考(ruanyifeng文章).不要苦恼，如果你对此仍然很抓耳挠腮.使用redux-sage你不需要javascript异步编程的博士学位.

因为使用了generators的缘故,我们能创建一个顺序执行的命令序列，用来描述复杂的异步操作流程(workflows).整个图片的加载流程序列如下：

```
   export function* loadImages() {
  try {
    const images = yield call(fetchImages);
    yield put({type: 'IMAGES_LOADED', images})
    yield put({type: 'IMAGE_SELECTED', image: images[0]})
  } catch(error) {
    yield put({type: 'IMAGE_LOAD_FAILURE', error})
  }
}

export function* watchForLoadImages() {
  while(true) {
    yield take('LOAD_IMAGES');
    yield call(loadImages);
  }
}  
```
  
   
#### 第一个saga

我们将开始一个简单的saga实例,然后配置他连接到我们的应用.在`src`创建一个文件
`saga.js`

```
   export function* sayHello() {
  console.log('hello');
}
  ```
  ___
  我们的saga是一个简单的generator函数.函数后面的`*`作为标志,他也被叫做”super star”.
  
  现在在`main.js`文件中导入新函数,并且执行他.
  
  ```
  import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';

import Gallery from './Gallery';

import { createStore } from 'redux'
import {Provider} from 'react-redux';
import reducer from './reducer'

+import {sayHello} from './sagas';
+sayHello();

const store = createStore(reducer);

ReactDOM.render(
  <Provider store={store}>
    <Gallery />
  </Provider>,
  document.getElementById('root')
);
```

不管你盯住终端多长时间,“hello”永远不会出现.
这是因为`sayHello`是一个generator！Generator 不会立即执行.如果你把代码该为`sayHello().next();`你的“hello”就出现了.不用担心,我们不会总是调用`next`.正如Redux,redux-saga用来消除应用开发中的痛苦.

配置 redux-sage

```
   import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';

import Gallery from './Gallery';

-import { createStore } from 'redux'
+import { createStore, applyMiddleware } from 'redux'
+import createSagaMiddleware from 'redux-saga'
import {Provider} from 'react-redux';
import reducer from './reducer'

import {sayHello} from './sagas';
-sayHello()

-const store = createStore(reducer);
+const store = createStore(
+  reducer,
+  applyMiddleware(createSagaMiddleware(sayHello))
+);

ReactDOM.render(
  <Provider store={store}>
    <Gallery />
  </Provider>,
  document.getElementById('root')
);
```

  我们已从Redux导入了`applyMiddleware`函数.从redux-saga导入`createSagaMiddleware`函数.当我们创建store的时候,我们需要通过中间件提供Redux需要的功能.在这个实例中,我们会调用`applyMiddleware`函数,这个函数返回`createSagaMiddleware(sayHello)`的结果.在幕后,redux-saga加载`sayHello`函数,仪式性的调用`next`函数.
  
  应该可以在终端中看到提示消息了.
  现在让我们构建加载图片的saga
  
#### 通过Saga加载图片数据

我们将删除出sayHello saga,使用`loadImages` saga

```
  -export function* sayHello() {
-  console.log('hello');
-}

+export function* loadImages() {
+  console.log('load some images please')
+}
```  

不要忘了更新`main.js`
  
```
import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';

import Gallery from './Gallery';

import { createStore, applyMiddleware } from 'redux'
import {Provider} from 'react-redux';
import createSagaMiddleware from 'redux-saga'
import reducer from './reducer'

-import {sayHello} from './sagas';
+import {loadImages} from './sagas';

const store = createStore(
  reducer,
-  applyMiddleware(createSagaMiddleware(sayHello))
+  applyMiddleware(createSagaMiddleware(loadImages))
);

ReactDOM.render(
  <Provider store={store}>
    <Gallery />
  </Provider>,
  document.getElementById('root')
);
```
  
  现在saga已经加载,在`saga.js`中添加`fetchImages`方法
  
```
     const API_KEY = 'a46a979f39c49975dbdd23b378e6d3d5';
const API_ENDPOINT = `https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=${API_KEY}&format=json&nojsoncallback=1&per_page=5`;

const fetchImages = () => {
  return fetch(API_ENDPOINT).then(function (response) {
    return response.json().then(function (json) {
      return json.photos.photo.map(
        ({farm, server, id, secret}) => `https://farm${farm}.staticflickr.com/${server}/${id}_${secret}.jpg`
      );
    })
  })
};

export function* loadImages() {
  const images = yield fetchImages();
  console.log(images)
}
```



 `fetchImages`方法返回一个promise对象.我们将调用`fetchImages`,但是现在我们要使用`yield`关键字.通过黑暗艺术和巫术,generators理解Promise对象,正如终端输出的日志显示,我们已经收获了一个图片URLs的数组.看看`loadImages`的代码,他看起来像是典型的同步操作代码.`yield`关键字是秘制调味酱,让我们的代码用同步格式执行异步操作活动.
  
#### 封装我们的异步API请求.
 
 首先来定义一下需要使用的api.他没有什么特殊的地方,实际上他和早先加载Flickr images的代码是相同的.我们创建`flickr.js`文件
 
```
   const API_KEY = 'a46a979f39c49975dbdd23b378e6d3d5';
const API_ENDPOINT = `https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=${API_KEY}&format=json&nojsoncallback=1&per_page=5`;

export const fetchImages = () => {
  return fetch(API_ENDPOINT).then(function (response) {
    return response.json().then(function (json) {
      return json.photos.photo.map(
        ({farm, server, id, secret}) => `https://farm${farm}.staticflickr.com/${server}/${id}_${secret}.jpg`
      );
    })
  })
};
```
 
 

严格意义上来说,不需要这么做,但是这会带来一定的好处.我们处在应用的边缘(boundaries of our application,意思是说在这里的代码可能是很多和远程服务器交互的代码，可能逻辑会很复杂),事情都有点乱.通过封装和远程API交互的逻辑,我们的代码将会很整洁,很容易更新.如果需要抹掉图片服务也会出奇的简单.

我们的`saga.js`看起来是这个样子：
 
```
  import {fetchImages} from './flickr';

export function* loadImages() {
  const images = yield fetchImages();
  console.log(images)
}
``` 

我们仍然需要在saga外获取数据,并且进入应用的state(使用异步获取的远程数据更新state).为了处理这个问题,我们将使用”effects”.

#### 从saga来更新应用

我们可以通过`dispatch`或者store作为参数来调用saga,但是这个方法时间一长就会给人造成些许的困扰.我们选择采用redux-saga提供的`put`方法.
首先我们更新`reducer.js`操作一个新的action类型`IMAGES_LOADED`.
```
const defaultState = {
+  images: []
}

export default function images(state = defaultState, action) {
  switch(action.type) {
    case 'IMAGE_SELECTED':
      return {...state, selectedImage: action.image};
+    case 'IMAGES_LOADED':
+      return {...state, images: action.images};
    default:
      return state;
  }
}     
```
  
  
  我们添加了新的分支,并从`defaultState`中删除了硬编码的URLs数据.`IMAGES_LOADED`分支现在返回一个更新的state,包含action的image数据.
  下一步我们更新saga:
```
	 import {fetchImages} from './flickr';
+import {put} from 'redux-saga/effects';

export function* loadImages() {
  const images = yield fetchImages();
+  yield put({type: 'IMAGES_LOADED', images})
}
```

导入`put`以后,我们在`loadImages`添加另外一行.他`yield` `put`函数调用的返回结果.在幕后,redux-saga 分发这些动作,reducer接收到了消息!
	   怎样才能使用特定类型的action来触发一个saga?
	   
#### 使用actions来触发saga工作流

Sagas变得越来越有用,因为我们有能力使用redux actions来触发工作流.当我们这样做,saga会在我们的应用中表现出更大的能力.首先我们创建一个新的saga.`watchForLoadImages`.

```
import {fetchImages} from './flickr';
-import {put} from 'redux-saga/effects';
+import {put, take} from 'redux-saga/effects';

export function* loadImages() {
  const images = yield fetchImages();
  yield put({type: 'IMAGES_LOADED', images})
}

+export function* watchForLoadImages() {
+  while(true) {
+    yield take('LOAD_IMAGES');
+    yield loadImages();
+  }
+}
```

新的saga使用的是while来保持一直激活和等待调用状态.在循环的内部,我们生成(yield)一个redux-sage调用方法:`take`.Take方法监听任何类型的actions,他也会使saga接受下一个yield.在上面的例子中我们调用了一个方法`loadImages`,初始化图片加载.

```
import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';

import Gallery from './Gallery';

import { createStore, applyMiddleware } from 'redux'
import {Provider} from 'react-redux';
import createSagaMiddleware from 'redux-saga'
import reducer from './reducer'

-import {loadImages} from './sagas';
+import {loadImages} from './watchForLoadImages';

const store = createStore(
  reducer,
-  applyMiddleware(createSagaMiddleware(loadImages))
+  applyMiddleware(createSagaMiddleware(watchForLoadImages))
);

ReactDOM.render(
  <Provider store={store}>
    <Gallery />
  </Provider>,
  document.getElementById('root')
);
```

更新了`main.js`以后,应用不再加载图片,我们需要在action creators中添加`loadImages`的`action`.
```
export const IMAGE_SELECTED = 'IMAGE_SELECTED';
+const LOAD_IMAGES = 'LOAD_IMAGES';

export function selectImage(image) {
  return {
    type: IMAGE_SELECTED,
    image
  }
}

+export function loadImages() {
+  return {
+    type: LOAD_IMAGES
+  }
+}
```

因为我们已经绑定了action creators(Action创建器),我们只需要在`Gallery`组件中调用这个action就可以了.

#### block(阻塞)和no-blocking(非阻塞)效应
现在我们的引用工作的足够好了,但是可能还有更多的问题需要考虑.`watchForLoadImages` saga包含 block effects.那么这到底是什么意思呢？这意味着在工作流中我们只能执行一次`LOAD_IMAGES`!在诸如我们现在构建的小型应用一样,这一点不太明显,实际上我们也仅仅加载了一次图片集.
实际上，普遍的做法是使用`fork` effect 代替  `yield` 来加载图片
.
```
export function* watchForLoadImages() {
  while(true) {
    yield take('LOAD_IMAGES');
-    yield loadImages();
+    yield fork(loadImages); //be sure to import it!
  }
}
```


使用`fork`助手(helper)函数,`watchForLoadImages`就变成了非阻塞saga了,再也不用考虑他是不是以前掉用过.redux-sagas 提供两个helpers,`takeEvery`和`takeLastest`（takeEvery监听多次action，不考虑是不是同一种action type,takeLatest只处理同一种action type的最后一次调用）.
####选择默认的图片
Sagas按照队列来执行acitons,所以添加更多的saga也很容易.
```
import {fetchImages} from './flickr';
import {put, take, fork} from 'redux-saga/effects';

export function* loadImages() {
  const images = yield fetchImages();
  yield put({type: 'IMAGES_LOADED', images})
+  yield put({type: 'IMAGE_SELECTED', image: images[0]})
}

export function* watchForLoadImages() {
  while(true) {
    yield take('LOAD_IMAGES');
    yield fork(loadImages);
  }
}
```

在 `loadImages`工作流上,我们可以yield put函数调用,action type是`IMAGE_SELECTED`.发送我们选择的图片(在这个例子中，发送的仅仅是图片的url的字符串).
#### 错误处理
如果在saga循环内部出现错误,我们要考虑提醒应用做出合理的回应.所有流程包装到try/catch语句块里就可以实现,捕获错误以后`put`一个提示信息作为`IMAGE_LOAD_FAILURE` action的内容.

```
import {fetchImages} from './flickr';
import {put, take, fork} from 'redux-saga/effects';

export function* loadImages() {
+  try {
    const images = yield fetchImages();
    yield put({type: 'IMAGES_LOADED', images})
    yield put({type: 'IMAGE_SELECTED', image: images[0]})
+  } catch(error) {
+    yield put({type: 'IMAGE_LOAD_FAILURE', error})
+  }
}

export function* watchForLoadImages() {
  while(true) {
    yield take('LOAD_IMAGES');
    yield fork(loadImages);
  }
}
```
#### Sagas的测试

在应用中使用Redux,测试变得相当的舒服. 看看我们的[鹅蛋头系列课程](https://egghead.io/series/react-testing-cookbook),可以了解到很多React的测试技术.
使用Redux-saga在棒的一个方面就是异步代码测试很容易.测试javascript异步代码真是一件苦差事.有了saga,我们不需要跳出引用的核心代码.Saga把javascript的痛点都抹掉了.是不是意味着我们要写更多的测试?对的.

我们会使用`tape`组件,首先做一些配置工作.

```
import test from 'tape';
import {put, take} from 'redux-saga/effects'
import {watchForLoadImages, loadImages} from './sagas';
import {fetchImages} from './flickr';

test('watchForLoadImages', assert => {
  const generator = watchForLoadImages();

  assert.end();
});
```

添加所有需要的组件,现在我们添加一个测试.这个测试接收一个名称和一个函数作为形参.在测试的函数体内部代码块,我们创建了一个saga生成器代码实例.在这个实例里面我们尅是测试saga的每一个动作.
```
import test from 'tape';
import {put, take} from 'redux-saga/effects'
import {watchForLoadImages, loadImages} from './sagas';
import {fetchImages} from './flickr';

test('watchForLoadImages', assert => {
  const generator = watchForLoadImages();

+  assert.deepEqual(
+    generator.next().value,
+    false,
+    'watchForLoadImages should be waiting for LOAD_IMAGES action'
+  );

  assert.end();
});
```

`assert.deepEqual`方法接收两个值,检查一下他们是不是深度相同(js对象的概念).第一行代码是`generator.next().value`的调用,这个调用使生成器从暂停中恢复,得到值.下一个值单单是一个`false`.我想看到他失败,最后一个参数描述了测试期待的行为.
在项目文件夹中命令行运行`npm test`看看结果:
```
  import test from 'tape';
import {put, take} from 'redux-saga/effects'
import {watchForLoadImages, loadImages} from './sagas';
import {fetchImages} from './flickr';

test('watchForLoadImages', assert => {
  const generator = watchForLoadImages();

+  assert.deepEqual(
+    generator.next().value,
+    false,
+    'watchForLoadImages should be waiting for LOAD_IMAGES action'
+  );

  assert.end();
});
```

测试结果和预期的一样失败,结果有点意思.实际的结论是`{TAKE:'LOAD_IMAGES'}`,这是我们调用`take('LOAD_IMAGES')`受到的结果.实际上,我们的saga’可以yield一个对象来代替调用`take`.但是`take`添加了一些代码,让我们少敲些代码.
```
import test from 'tape';
import {put, take} from 'redux-saga/effects'
import {watchForLoadImages, loadImages} from './sagas';
import {fetchImages} from './flickr';

test('watchForLoadImages', assert => {
  const generator = watchForLoadImages();

  assert.deepEqual(
    generator.next().value,
-    false
+    take('LOAD_IMAGES'),
    'watchForLoadImages should be waiting for LOAD_IMAGES action'
  );

  assert.end();
});
```

我们简单的调用`take`函数,就可以得到期待的结果了.

```
import test from 'tape';
import {put, take} from 'redux-saga/effects'
import {watchForLoadImages, loadImages} from './sagas';
import {fetchImages} from './flickr';

test('watchForLoadImages', assert => {
  const generator = watchForLoadImages();

  assert.deepEqual(
    generator.next().value,
    take('LOAD_IMAGES'),
    'watchForLoadImages should be waiting for LOAD_IMAGES action'
  );

+  assert.deepEqual(
+    gen.next().value,
+    false,
+    'watchForLoadImages should call loadImages after LOAD_IMAGES action is received'
+  );

  assert.end();
});
```

下一个测试使我们确信`loadImages`saga在流程的下一个阶段会被自动调用.
我们需要一个 false来检查结果.
更新一下saga代码,yield一个`loadImages` saga:
```
export function* watchForLoadImages() {
  while(true) {
    yield take('LOAD_IMAGES');
+    yield loadImages();
-    yield fork(loadImages); //be sure to import it!
  }
}
```

现在运行测试,将会看到下面结果：
```
✖ watchForLoadImages should call loadImages after LOAD_IMAGES action is received
---------------------------------------------------------------------------------
  operator: deepEqual
  expected: |-
    false
  actual: |-
    { _invoke: [Function: invoke] }
```

哼！`{ _invoke: [Function: invoke] }`绝对不是我们yield take想要的结果.
有问题.幸运的是redux-saga可以使用诸如`fork`一样的`effects`来解决这个问题.`fork`,`take`和其他的effect方法返容易满足测试要求的简单对象.这些effects返回的对象是一个指导redux-saga进行任务执行的集合.这一点对于测试来说非常的优雅,因为我们不用担心类似远程服务请求的副作用.有了redux-saga,我们把注意点放到请求执行的命令上.
下面让我们更新一下saga,再一次使用`fork`.

```
export function* watchForLoadImages() {
  while(true) {
    yield take('LOAD_IMAGES');
-    yield loadImages();
+    yield fork(loadImages);

  }
}
```


这里使用`yield fork(loadImages)`直接代替`loadImages`.需要注意的是我们还没有执行`loadImages`,而是作为参数传递给`fork`.
再次运行`npm test`.
```
✖ watchForLoadImages should call loadImages after LOAD_IMAGES action is received
---------------------------------------------------------------------------------
  operator: deepEqual
  expected: |-
    false
  actual: |-
    { FORK: { args: [], context: null, fn: [Function: loadImages] } }
```

结果得到了一个单纯对象而不是一个函数调用.函数在浏览器端也同时加载了,但是我们现在可以轻松的在saga 工作流里测试这个步骤.

```
import test from 'tape';
import {put, take} from 'redux-saga/effects'
import {watchForLoadImages, loadImages} from './sagas';
import {fetchImages} from './flickr';

test('watchForLoadImages', assert => {
  const generator = watchForLoadImages();

  assert.deepEqual(
    generator.next().value,
    take('LOAD_IMAGES'),
    'watchForLoadImages should be waiting for LOAD_IMAGES action'
  );

  assert.deepEqual(
    generator.next().value,
-    false,
+    yield fork(loadImages),
    'watchForLoadImages should call loadImages after LOAD_IMAGES action is received'
  );

  assert.end();
});
```

测试`loadImages`saga是一样的,只需要把`yield fetchImages`更新为`yield fork(fetchImages)`.

```
test('loadImages', assert => {
  const gen = loadImages();

  assert.deepEqual(
    gen.next().value,
    call(fetchImages),
    'loadImages should call the fetchImages api'
  );

  const images = [0];

  assert.deepEqual(
    gen.next(images).value,
    put({type: 'IMAGES_LOADED', images}),
    'loadImages should dispatch an IMAGES_LOADED action with the images'
  );

  assert.deepEqual(
    gen.next(images).value,
    put({type: 'IMAGE_SELECTED', image: images[0]}),
    'loadImages should dispatch an IMAGE_SELECTED action with the first image'
  );

  const error = 'error';

  assert.deepEqual(
    gen.throw(error).value,
    put({type: 'IMAGE_LOAD_FAILURE', error}),
    'loadImages should dispatch an IMAGE_LOAD_FAILURE if an error is thrown'
  );

  assert.end();
});
```

特别注意最后一个`assert`.这个断言测试使用异常捕获代替生成器函数的next方法.另一个非常酷的地方是：可以传值.注意看代码,我们创建了`images`常量,并且传递到next函数.saga可以在接下来的任务序列中使用传递的值.
 太棒了,这种方法是测试异步编程的程序员梦寐以求的技术.
 
##### 接下来做什么？

 
 你可以[fork一下这个例子的代码](https://github.com/joelhooks/egghead-react-redux-image-gallery).
 
 如果你想扩充这个应用,可以做一下几个方面的工作.
- 做一个幻灯显示下一张要显示的图片
- 允许使用者搜索Flickr图片
- 添加其他提供图片的API
- 允许用户选择喜欢的API进行搜索.

我们仅仅和生成器碰了一下面,但是即便如此,希望在联合使用redux-saga library,Redux和React的时候给你一些帮助.