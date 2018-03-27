---
title: 翻译|开启React,Redux和Immutable之旅:测试驱动教程(part1)
date: 2017-03-15 14:59:17
categories: 技术备忘
tags: [react,redux,Immutable.js]
---

>翻译版本,[原文请见,第一部分](http://www.theodo.fr/blog/2016/03/getting-started-with-react-redux-and-immutable-a-test-driven-tutorial-part-1/),[第二部分](http://www.theodo.fr/blog/2016/03/getting-started-with-react-redux-and-immutable-a-test-driven-tutorial-part-2/)



几周以前,我正在漫无目的的浏览[Hacker News](http://news.ycombinator.com/),读到一篇关于Redux的头条新闻,Redux的内容我是了解,但是另一个谈到的问题`javascript fatigue`(JavaScript 疲劳)已经困扰我了,所以我没有太关心,知道读到Redux的几个特征.

* 强化了函数式编程,确保app行为的可预测性
* 允许app的同构,客户端和服务端的大多数逻辑都可以共享
* 时间旅行的debugger?有可能吗？

Redux似乎是React程序state管理的优雅方法,再者谁说的时间旅行不可能？所以我读了[文档](http://news.ycombinator.com/)和一篇非常精彩的教程[@teropa:A Comprehensive Guide to Test-First Development with Redux,React,and Immutable](http://teropa.info/blog/2015/09/10/full-stack-redux-tutorial.html)(这一篇也是我写作的主要灵感来源).

我喜欢Redux,代码非常优雅,debugger令人疯狂的伟大.我的意思是-看看这个![todo-action](http://www.theodo.fr/uploads/blog//2016/02/time-travel.gif)

接下来的教程第一部分希望引导你理解Redux运行的原则.教程的目的仅限于(客户端,没有同构,是比较简单的app)保持教程的简明扼要.如果你想发掘的更深一点,我仅建议你阅读上面提高的那个教程.对比版的Github repo在[这里](https://github.com/phacks/redux-todomvc),共享代码贴合教程的步骤.如果你对代码或者教程有任何问题和建议,最好能留下留言.

编辑按:文章已经更新为ES2015版的句法.

## APP

为了符合教程的目的,我们将建一个经典的[TodoMVC](http://todomvc.com/),为了记录需要,需求如下：

* 每一个todo可以激活或者完成
* 可以添加,编辑,删除一个todo
* 可以根据它的status来过滤筛选todos
* 激活的todos的数目显示在底部
* 完成的Todo理解可以删除


## Reudux和Immutable：使用函数编程去营救
回到几个月前,我正在开发一个webapp包含仪表板. 随着app的成长,我们注意到越来越多的有害的bugs,藏在代码角落里,很难发现.类似:“如果你要导航到这一页,点击按钮,然后回到主页,喝一杯咖啡,回到这一页然后点击两次,奇怪的事情发生了.”这些bug的来源要么是异步操作(side effects)或者逻辑:一个action可能在app中有意想不到的影响,这个有时候我们还发现不了.

这就是Redux之所以存在的威力:整个app的state是一个单一的数据结构,state tree.这一点意思是说：在任何时刻,展示给用户的内容仅仅是state tree结果,这就是单一来源的真相(用户界面的显示内容是由state tree来决定的).每一个action接收state,应用相应的修改(例如,添加一个todo),输出更新的state tree.更新的结果渲染展示给用户.里面没有模糊的异步操作,没有变量的引用引起的不经意的修改.这个步骤使得app有了更好的结构,分离关注点,dubugging也更好用了.

[*Immutable*](https://facebook.github.io/immutable-js)是有Facebook开发的助手函数库,提供一些工具去创建和操作immutable数据结构.尽管在Redux也不是一定要使用它,但是它通过禁止对象的修改,强化了函数式编程方法.有了immutable,当我们想更新一个对象,实际上我们修改的是一个新创建的的对象,原先的对象保持不变.

这里是“[Immutable文档](https://facebook.github.io/immutable-js)”里面的例子:

```js
 var map1 = Immutable.Map({a:1, b:2, c:3});
var map2 = map1.set('b', 2);
assert(map1 === map2); // no change
var map3 = map1.set('b', 50);
assert(map1 !== map3); // change
```

我们更新了`map1`的一个值,`map1`对象保持不变,一个新的对象`map3`被创建了.

Immutable在store中被用来储存我们的app的state tree.很快我们会看到Immutable提供了一下操作对象的简单和有效的方法.

## 配置项目
声明:一些配置有@terops的教程启发.

注意事项:推荐使用Node.js>=4.0.0.你可以使用nvm(node version manager)来切换不同的node.js的版本.

[这里是比较版本的提交](https://github.com/phacks/redux-todomvc/commit/9e2d23ca16980566d9fcaeebbf198031ec55d42f)

开始配置项目:

```
mkdir redux-todomvc
cd redux-todomvc
npm init -y
```

项目的目录结构如下:

```
├── dist
│   ├── bundle.js
│   └── index.html
├── node_modules
├── package.json
├── src
├── test
└── webpack.config.js
```

首先创建一个简单的HTML页面,用来运行我们的app
`dist/index.html`
```html
 <!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>React TodoMVC</title>
</head>
<body>
  <div id="app"></div>
  <script src="bundle.js"></script>
</body>
</html>
```

有了这个文件,我们写一个简单的脚本文件看看包安装的情况
`src/index.js`

```js
console.log('Hello world !');
```

我们将会使用[Webpack]来打包成为`bundle.js`文件.Webpack的特性是速度,容易配置,大部分是热更新的.代码的更新不需要重新加载,意味着app的state保持热加载.

让我们安装webpack:

`npm install —save-dev webpack@1.12.14 webpack-dev-server@1.14.1`

app使用ES2015的语法,带来一些优异的特性和一些语法糖.如果你想了解更多的ES2015内容,这个[recap](https://github.com/DrkSephy/es6-cheatsheet)是一个不错的资源.

Babel用来把ES2015的语法改变为普通的JS语法:
`npm install —save-dev babel-core@6.5.2 babel-loader@6.2.4 babel-preset-es2015@6.5.0`

我们将使用JSX语法编写React组件,所以让我们安装Babel React package：
`npm install —save-dev babel-preset-react@6.5.0`

配置webpack输出源文件:
`package.json`
```js
 "babel": {
  "presets": ["es2015", "react"]
}
```

`webpack.config.js`

```js
 module.exports = {
  entry: [
    './src/index.js'
  ],
  module: {
    loaders: [{
      test: /\.jsx?$/,
      exclude: /node_modules/,
      loader: 'babel'
    }]
  },
  resolve: {
    extensions: ['', '.js', '.jsx']
  },
  output: {
    path: __dirname + '/dist',
    publicPath: '/',
    filename: 'bundle.js'
  },
  devServer: {
    contentBase: './dist'
  }
};
```

现在添加React和React热加载组件到项目中:
```json
 npm install --save react@0.14.7 react-dom@0.14.7
 npm install --save-dev react-hot-loader@1.3.0
```

为了让热加载能运行,webpack.config.js文件中要做一些修改.

`webpack.config.js`
```
 var webpack = require('webpack'); // Requiring the webpack lib

module.exports = {
  entry: [
    'webpack-dev-server/client?http://localhost:8080', // Setting the URL for the hot reload
    'webpack/hot/only-dev-server', // Reload only the dev server
    './src/index.js'
  ],
  module: {
    loaders: [{
      test: /\.jsx?$/,
      exclude: /node_modules/,
      loader: 'react-hot!babel' // Include the react-hot loader
    }]
  },
  resolve: {
    extensions: ['', '.js', '.jsx']
  },
  output: {
    path: __dirname + '/dist',
    publicPath: '/',
    filename: 'bundle.js'
  },
  devServer: {
    contentBase: './dist',
    hot: true // Activate hot loading
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin() // Wire in the hot loading plugin
  ]
};
```

### 配置单元测试框架

我们将使用Mocha和Chai来进行测试工作.这两个工具广泛的被使用,他们的输出内容对于测试驱动开发非常的好.Chai-immutable是一个chai插件,用来处理immutable数据结构.

```
npm install --save immutable@3.7.6
npm install --save-dev mocha@2.4.5 chai@3.5.0 chai-immutable@1.5.3
```

在我们的例子中,我们不会依赖浏览器为基础的测试运行器例如Karma-替代方案是我们使用jsdom库,它将会使用纯javascirpt创建一个假DOM,这样做让我们的测试更加快速.

`npm install —save-dev jsdom@8.0.4`

我们也需要为测试写一个启动脚本,要考虑到下面的内容.

* 模拟`document`和`window`对象,通常是由浏览器提供
* 通过`chia-immutable`告诉chai组件我们要使用immutable数据结构

`test/setup.js`

```js
 import jsdom from 'jsdom';
import chai from 'chai';
import chaiImmutable from 'chai-immutable';

const doc = jsdom.jsdom('<!doctype html><html><body></body></html>');
const win = doc.defaultView;

global.document = doc;
global.window = win;

Object.keys(window).forEach((key) => {
  if (!(key in global)) {
    global[key] = window[key];
  }
});

chai.use(chaiImmutable);
```

更新一下`npm test`脚本
`package.json`
```json
 "scripts": {
  "test": "mocha --compilers js:babel-core/register --require ./test/setup.js 'test/**/*.@(js|jsx)'",
  "test:watch": "npm run test -- --watch --watch-extensions jsx"
},
```

`npm run test:watch`命令在windows操作系统下似乎不能工作.

现在,如果我们运行`npm run test:watch`,所有test目录里的`.js`,`.jsx`文件在更新自身或者源文件的时候,将会运行mocha测试.

配置完成了：我们可以在终端中运行`webpack-dev-server`,打开另一个终端,`npm run test:watch`.在浏览器中打开[localhost:8080](localhost:8080).检查`hello world!`是否出现在终端中.

## 构建state tree

之前提到过,state tree是能提供app所有信息的数据结构.这个结构需要在实际开发之前经过深思熟虑,因为它将影响一些代码的结构和交互作用.

作为示例,我们app是一个TODO list由几个条目组合而成

![state tree 1](https://ww1.sinaimg.cn/large/006tNc79ly1fdtq17eheyj30c70600sj.jpg)
每一个条目有一个文本,为了便于操作,设一个id,此外每个item有两个状态之一:活动或者完成：最后一个条目需要一个可编辑的状态(当用户想编辑的文本的时候),
所以我们需要保持下面的数据结构:
![state tree 2](https://ww2.sinaimg.cn/large/006tNc79ly1fdtqcw4ofzj30jy083jra.jpg)

也有可能基于他们的状态进行筛选,所以我们天剑`filter`条目来获取最终的state tree:
![sate tree 3](https://ww1.sinaimg.cn/large/006tNc79ly1fdtqcvvz68j30p60ar748.jpg)


## 创建UI


首先我们把app分解为下面的组件:
* `TodoHeader`组件是创建新todo的输入组件
* `TodoList`组件是todo的列表
* `todoItem`是一个todo
* `todoInput`是编辑todo的输入框
* `TodoTools`是显示未完成的条目数量,过滤器和清除完成的按钮
* `footer`是显示信息的,没有具体的逻辑

我们也创建`TodoApp`组件组织所有的其他组件.

首次运行我们的组件

*提示:*[运行这个版本](https://github.com/phacks/redux-todomvc/commit/d1d2a56a8d2b4f898ed8fdf20f55e7f7f11ad6ad)

正如我们所见的,我们将会把所有组件放到合并成一个`TodoApp`组件.所以让我们添加组件到`index.html`文件的`#app`DIV中:
`src/index.jsx`

```js
import React from 'react';
import ReactDOM from 'react-dom';
import {List, Map} from 'immutable';

import TodoApp from './components/TodoApp';

const todos = List.of(
  Map({id: 1, text: 'React', status: 'active', editing: false}),
  Map({id: 2, text: 'Redux', status: 'active', editing: false}),
  Map({id: 3, text: 'Immutable', status: 'completed', editing: false})
);

ReactDOM.render(
  <TodoApp todos={todos} />,
  document.getElementById('app')
);
```


因为我们在`index.jsx`文件中使用JSX语法,需要在wabpack中扩展`.jsx`.修改如下:
`webpack.config.js`
```js
 entry: [
  'webpack-dev-server/client?http://localhost:8080',
  'webpack/hot/only-dev-server',
  './src/index.jsx' // Change the index file extension
],
```

## 编写todo list UI

现在我们编写第一版本的`TodoApp`组件,用来显示todo项目列表:
`src/components/TodoApp.jsx`
```js
 import React from 'react';

export default class TodoApp extends React.Component {
  getItems() {
    return this.props.todos || [];
  }
  render() {
    return <div>
      <section className="todoapp">
        <section className="main">
          <ul className="todo-list">
            {this.getItems().map(item =>
              <li className="active" key={item.get('text')}>
                <div className="view">
                  <input type="checkbox"
                         className="toggle" />
                  <label htmlFor="todo">
                    {item.get('text')}
                  </label>
                  <button className="destroy"></button>
                </div>
              </li>
            )}
          </ul>
        </section>
      </section>
    </div>
  }
};
```

要记住两件事情:
第一个,如果你看到的结果不太好,修复它,我们将会使用[todomvc-app-css](https://github.com/tastejs/todomvc-app-css)包来补充一些需要的样式
```js
npm install --save todomvc-app-css@2.0.4
npm install style-loader@0.13.0 css-loader@0.23.1 --save-dev
```

我们需要告诉webpack去加载css 样式文件:
`webpack.config.js`
```
// ...
module: {
  loaders: [{
    test: /\.jsx?$/,
    exclude: /node_modules/,
    loader: 'react-hot!babel'
  }, {
    test: /\.css$/,
    loader: 'style!css' // We add the css loader
  }]
},
//...
```

然后在`inde.jsx`文件中添加样式:
`src/index.jsx`
```
 // ...
require('../node_modules/todomvc-app-css/index.css');

ReactDOM.render(
  <TodoApp todos={todos} />,
  document.getElementById('app')
);
```

第二件事是:代码似乎很复杂,这就是我们为什么要创建两个或者多个组件的原因:`TodoList`和`TodoItem`将会分别关注条目列表和单个的条目.

[这一部分的提交代码](https://github.com/phacks/redux-todomvc/commit/90fe2cc5f8e1c20546c702b91230369c896b9b81)

`src/components/TodoApp.jsx`
```js
 import React from 'react';
import TodoList from './TodoList'

export default class TodoApp extends React.Component {
  render() {
    return <div>
      <section className="todoapp">
        <TodoList todos={this.props.todos} />
      </section>
    </div>
  }
};
```

在`TodoList`组件中根据获取的props为每一个条目显示一个`TodoItem`组件.

`src/components/TodoList.jsx`
```js
 import React from 'react';
import TodoItem from './TodoItem';

export default class TodoList extends React.Component {
  render() {
    return <section className="main">
      <ul className="todo-list">
        {this.props.todos.map(item =>
          <TodoItem key={item.get('text')}
                    text={item.get('text')} />
        )}
      </ul>
    </section>
  }
};
```

`src/components/TodoItem.jsx`
```js
 import React from 'react';

export default class TodoItem extends React.Component {
  render() {
    return <li className="todo">
      <div className="view">
        <input type="checkbox"
               className="toggle" />
        <label htmlFor="todo">
          {this.props.text}
        </label>
        <button className="destroy"></button>
      </div>
    </li>
  }
};
```

在我们深入用户的交互操作之前,我们先在组件`TodoItem`中添加一个input用于编辑
`src/componensts/TodoItem.jsx`
```js
 import React from 'react';

import TextInput from './TextInput';

export default class TodoItem extends React.Component {

  render() {
    return <li className="todo">
      <div className="view">
        <input type="checkbox"
               className="toggle" />
        <label htmlFor="todo">
          {this.props.text}
        </label>
        <button className="destroy"></button>
      </div>
      <TextInput /> // We add the TextInput component
    </li>
  }
};

```

`TextInput`组件如下
`src/compoents/TextInput.jsx`
```js
import React from 'react';

export default class TextInput extends React.Component {
  render() {
    return <input className="edit"
                  autoFocus={true}
                  type="text" />
  }
};
```

## ”纯“组件的好处：PureRenderMixin

[这部分的提交代码](https://github.com/phacks/redux-todomvc/commit/d9a60c94ba194f63a21df0d2e5d1e6d6a2cca506)

除了允许函数式编程的样式,我们的UI是单纯的,可以使用`PureRenderMixin`来提升速度,正如[React 文档](https://facebook.github.io/react/docs/pure-render-mixin.html):
如果你的React的组件渲染函数是”纯“(换句话就是,如果使用相同的porps和state,总是会渲染出同样的结果),你可以使用mixin在同一个案例转给你来提升性能.

正如[React文档](https://facebook.github.io/react/docs/pure-render-mixin.html)(我们也会在第二部分看到`TodoApp`组件有额外的角色会阻止`PureRenderMixin`的使用)展示的mixin也非常容易的添加到我们的子组件中:
`npm install --save react-addons-pure-render-mixin@0.14.7`
`src/components/TodoList.jsc`

```js
 import React from 'react';
import PureRenderMixin from 'react-addons-pure-render-mixin'
import TodoItem from './TodoItem';

export default class TodoList extends React.Component {
  constructor(props) {
    super(props);
    this.shouldComponentUpdate = PureRenderMixin.shouldComponentUpdate.bind(this);
  }
  render() {
    // ...
  }
};
```

`src/components/TodoItem/jsx`
```js
import React from 'react';
import PureRenderMixin from 'react-addons-pure-render-mixin'
import TextInput from './TextInput';

export default class TodoItem extends React.Component {
  constructor(props) {
    super(props);
    this.shouldComponentUpdate = PureRenderMixin.shouldComponentUpdate.bind(this);
  }
  render() {
    // ...
  }
};
```

`src/components/TextInput.jsx`
```js
import React from 'react';
import PureRenderMixin from 'react-addons-pure-render-mixin'

export default class TextInput extends React.Component {
  constructor(props) {
    super(props);
    this.shouldComponentUpdate = PureRenderMixin.shouldComponentUpdate.bind(this);
  }
  render() {
    // ...
  }
};
```

## 在list组件中处理用户的actions

好了,现在我们配置好了list组件.然而我们没有考虑添加用户的actions和怎么添加进去组件.
### props的力量

在React中,`props`对象是当我们实例化一个容器(container)的时候,通过设定的attributes来设定.例如,如果我们实例化一个`TodoItem`元素:
```
<TodoItem text={'Text of the item'} />
```
然后我们在`TodoItem`组件中获取`this.props.text`变量:
```js
 // in TodoItem.jsx
console.log(this.props.text);
// outputs 'Text of the item'
```

Redux构架中强化使用`props`.基础的原理是state几乎都存在于他的props里面.换一种说法：对于同样一组props,两个元素的实例应该输出完全一样的结果.正如之前我们看到的,整个app的state都包含在一个state tree中:意思是说,state tree 如果通过`props`的方式传递到组件,将会完整和可预期的决定app的视觉输出.

### TodoList组件

[这一部分的代码修改](https://github.com/phacks/redux-todomvc/commit/69707f07b6e9cbca7558cb85fcabff54615c1737)

在这一部分和接下来的一部分,我们将会了解一个测试优先的方法.

为了帮助我们测试组件,React库提供了`TestUtils`工具插件,有一下方法:
* `renderIntoDocument`,渲染组件到附加的DOM节点
* `scryRenderDOMComponentsWIthTag`,使用提供的标签(例如`li`,`input`)在DOM中找到所有的组件实例.
* `scryRederDOMComponentsWithClass`,同上使用的是类
* `Simulate`,模拟用户的actions(例如 点击,按键,文本输入…)

`TestUtils`插件没有包含在`react`包中,所以需要单独安装
`npm install --save-dev react-addons-test-utils@0.14.7`

 我们的第一个测试将确保`Todolist`组件中,如果`filter`props被设置为`active`,将会展示所有的活动条目:
 `test/components/TodoList_spec.jsx`
 
  ```js
   import React from 'react';
import TestUtils from 'react-addons-test-utils';
import TodoList from '../../src/components/TodoList';
import {expect} from 'chai';
import {List, Map} from 'immutable';

const {renderIntoDocument,
       scryRenderedDOMComponentsWithTag} = TestUtils;

describe('TodoList', () => {
  it('renders a list with only the active items if the filter is active', () => {
    const todos = List.of(
      Map({id: 1, text: 'React', status: 'active'}),
      Map({id: 2, text: 'Redux', status: 'active'}),
      Map({id: 3, text: 'Immutable', status: 'completed'})
    );
    const filter = 'active';
    const component = renderIntoDocument(
      <TodoList filter={filter} todos={todos} />
    );
    const items = scryRenderedDOMComponentsWithTag(component, 'li');

    expect(items.length).to.equal(2);
    expect(items[0].textContent).to.contain('React');
    expect(items[1].textContent).to.contain('Redux');
  });
});
  ```
我们可以看到测试失败了,期待的是两个活动条目,但是实际上是三个.这是再正常不过的了,因为我们没有编写实际筛选的逻辑:
`src/components/TodoList.jsx`
```js
// ...
export default class TodoList extends React.Component {
  // Filters the items according to their status
  getItems() {
    if (this.props.todos) {
      return this.props.todos.filter(
        (item) => item.get('status') === this.props.filter
      );
    }
    return [];
  }
  render() {
    return <section className="main">
      <ul className="todo-list">
        // Only the filtered items are displayed
        {this.getItems().map(item =>
          <TodoItem key={item.get('text')}
                    text={item.get('text')} />
        )}
      </ul>
    </section>
  }
};
```
  
  第一个测试通过了.别停下来,让我们添加筛选器:`all`和`completed:`
  `test/components/TodoList_spec.js`
  ```js
  // ...
describe('TodoList', () => {
  // ...
  it('renders a list with only completed items if the filter is completed', () => {
    const todos = List.of(
      Map({id: 1, text: 'React', status: 'active'}),
      Map({id: 2, text: 'Redux', status: 'active'}),
      Map({id: 3, text: 'Immutable', status: 'completed'})
    );
    const filter = 'completed';
    const component = renderIntoDocument(
      <TodoList filter={filter} todos={todos} />
    );
    const items = scryRenderedDOMComponentsWithTag(component, 'li');

    expect(items.length).to.equal(1);
    expect(items[0].textContent).to.contain('Immutable');
  });

  it('renders a list with all the items', () => {
    const todos = List.of(
      Map({id: 1, text: 'React', status: 'active'}),
      Map({id: 2, text: 'Redux', status: 'active'}),
      Map({id: 3, text: 'Immutable', status: 'completed'})
    );
    const filter = 'all';
    const component = renderIntoDocument(
      <TodoList filter={filter} todos={todos} />
    );
    const items = scryRenderedDOMComponentsWithTag(component, 'li');

    expect(items.length).to.equal(3);
    expect(items[0].textContent).to.contain('React');
    expect(items[1].textContent).to.contain('Redux');
    expect(items[2].textContent).to.contain('Immutable');
  });
});
  ```
  
  第三个测试失败了,因为`all`筛选器更新组件的逻辑稍稍有点不同
  `src/components/TodoList.jsx`
  ```
   // ...
export default React.Component {
  // Filters the items according to their status
  getItems() {
    if (this.props.todos) {
      return this.props.todos.filter(
        (item) => this.props.filter === 'all' || item.get('status') === this.props.filter
      );
    }
    return [];
  }
  // ...
});
  ```
在这一点上,我们知道显示在app中的条目都是经过`filter`属性过滤的.如果在浏览器中看看结果,没有显示任何条目,因为我们还没有设置：
`src/index.jsx`
```js
 // ...
const todos = List.of(
  Map({id: 1, text: 'React', status: 'active', editing: false}),
  Map({id: 2, text: 'Redux', status: 'active', editing: false}),
  Map({id: 3, text: 'Immutable', status: 'completed', editing: false})
);

const filter = 'all';

require('../node_modules/todomvc-app-css/index.css')

ReactDOM.render(
  <TodoApp todos={todos} filter = {filter}/>,
  document.getElementById('app')
);
```
 

`src/components/TodoApp.jsx`

```
// ...
export default class TodoApp extends React.Component {
  render() {
    return <div>
      <section className="todoapp">
        // We pass the filter props down to the TodoList component
        <TodoList todos={this.props.todos} filter={this.props.filter}/>
      </section>
    </div>
  }
};
``` 
使用在`index.jsc`文件中声明的`filter`常量过滤以后,我们的条目重新出现了.

### TodoItem component
[这部分的代码修改](https://github.com/phacks/redux-todomvc/commit/71d2835620f4ba6f3fc3665327f13ec4fba62eee)

现在,让我们关注一下`TodoItem`组件.首先,我们想确信`TodoItem`组件真正渲染一个条目.我们也想测试一下还没有测试的特性,就是当一个条目完成的时候,他的文本中间有一条线
`test/components/TodoItem_spec.js`
 ```js
  import React from 'react';
import TestUtils from 'react-addons-test-utils';
import TodoItem from '../../src/components/TodoItem';
import {expect} from 'chai';

const {renderIntoDocument,
       scryRenderedDOMComponentsWithTag} = TestUtils;

describe('TodoItem', () => {
  it('renders an item', () => {
    const text = 'React';
    const component = renderIntoDocument(
      <TodoItem text={text} />
    );
    const todo = scryRenderedDOMComponentsWithTag(component, 'li');

    expect(todo.length).to.equal(1);
    expect(todo[0].textContent).to.contain('React');
  });

  it('strikes through the item if it is completed', () => {
    const text = 'React';
    const component = renderIntoDocument(
      <TodoItem text={text} isCompleted={true}/>
    );
    const todo = scryRenderedDOMComponentsWithTag(component, 'li');

    expect(todo[0].classList.contains('completed')).to.equal(true);
  });
});
 ```
 
 为了使第二个测试通过,如果条目的状态是`complete`我们使用了类`complete`,它将会通过props传递向下传递.我们将会使用`classnames`包来操作我们的DOM类.
 `npm install —save classnames`
 
`src/components/TodoItem.jsx`
  
  ```js
   import React from 'react';
// We need to import the classNames object
import classNames from 'classnames';

import TextInput from './TextInput';

export default class TodoItem extends React.Component {
  render() {
    var itemClass = classNames({
      'todo': true,
      'completed': this.props.isCompleted
    });
    return <li className={itemClass}>
      // ...
    </li>
  }
};
  ```
  
一个item在编辑的时候外观应该看起来不一样,由`isEditing`props来包裹.
`test/components/TodoItem_spec.js`
  ```js
   // ...
describe('TodoItem', () => {
  //...

  it('should look different when editing', () => {
    const text = 'React';
    const component = renderIntoDocument(
      <TodoItem text={text} isEditing={true}/>
    );
    const todo = scryRenderedDOMComponentsWithTag(component, 'li');

    expect(todo[0].classList.contains('editing')).to.equal(true);
  });
});

  ```
 为了使测试通过,我们仅仅需要更新`itemClass`对象:
 `src/components/TodoItem.jsx`
 ```js
  // ...
export default class TodoItem extends React.Component {
  render() {
    var itemClass = classNames({
      'todo': true,
      'completed': this.props.isCompleted,
      'editing': this.props.isEditing
    });
    return <li className={itemClass}>
      // ...
    </li>
  }
};
 ```
 条目左侧的checkbox如果条目完成,应该标记位checked:
 `test/components/TodoItem_spec.js`
 ```js
  // ...
describe('TodoItem', () => {
  //...

  it('should be checked if the item is completed', () => {
    const text = 'React';
    const text2 = 'Redux';
    const component = renderIntoDocument(
      <TodoItem text={text} isCompleted={true}/>,
      <TodoItem text={text2} isCompleted={false}/>
    );
    const input = scryRenderedDOMComponentsWithTag(component, 'input');
    expect(input[0].checked).to.equal(true);
    expect(input[1].checked).to.equal(false);
  });
});
 ```
 
 React有个设定checkbox输入state的方法:`defaultChecked`.
 `src/components/TodoItem.jsx`
  ```js
   // ...
export default class TodoItem extends React.Component {
  render() {
    // ...
    return <li className={itemClass}>
      <div className="view">
        <input type="checkbox"
               className="toggle"
               defaultChecked={this.props.isCompleted}/>
        // ...
      </div>
    </li>
  }
};

  ```
  
  我们也从`TodoList`组件向下传递`isCompleted`和`isEditing`props.
  `src/components/TodoList.jsx`
  ```js
   // ...
export default class TodoList extends React.Component {
  // ...
  // This function checks whether an item is completed
  isCompleted(item) {
    return item.get('status') === 'completed';
  }
  render() {
    return <section className="main">
      <ul className="todo-list">
        {this.getItems().map(item =>
          <TodoItem key={item.get('text')}
                    text={item.get('text')}
                    // We pass down the info on completion and editing
                    isCompleted={this.isCompleted(item)}
                    isEditing={item.get('editing')} />
        )}
      </ul>
    </section>
  }
};
  ```
截止目前,我们已经能够在组件中反映出state：例如,完成的条目将会被划线.然而一个webapp将会处理诸如点击按钮的操作.在Redux的模式中,这个操作也通过`porps`来执行,稍稍特殊的是通过在props中传递回调函数来完成.通过这种方式,我们再次把UI和App的逻辑处理分离开:组件根本不需要知道按钮点击的操作具体是什么,仅仅是点击触发了一些事情.

为了描述这个原理,我们将会测试如果用户点击了delete按钮(红色X),`delteItem`函数将会被调用.

 [这部分的代码修改](https://github.com/phacks/redux-todomvc/commit/b3a6851e8a9f65f1c44e66046bedd1db18c19a48) 
 
 `test/components/TodoItem_spec.jsx`
 ```js
  / ...
// The Simulate helper allows us to simulate a user clicking
const {renderIntoDocument,
       scryRenderedDOMComponentsWithTag,
       Simulate} = TestUtils;

describe('TodoItem', () => {
  // ...
  it('invokes callback when the delete button is clicked', () => {
    const text = 'React';
    var deleted = false;
    // We define a mock deleteItem function
    const deleteItem = () => deleted = true;
    const component = renderIntoDocument(
      <TodoItem text={text} deleteItem={deleteItem}/>
    );
    const buttons = scryRenderedDOMComponentsWithTag(component, 'button');
    Simulate.click(buttons[0]);

    // We verify that the deleteItem function has been called
    expect(deleted).to.equal(true);
  });
});

 ```
 
 为了是这个测试通过,我们必须在delete按钮声明一个`onClick`句柄,他将会调用经过props传递的`deleteItem`函数.
 
 `src/components/TodoItem.jsx`
 ```js
  // ...
export default class TodoItem extends React.Component {
  render() {
    // ...
    return <li className={itemClass}>
      <div className="view">
        // ...
        // The onClick handler will call the deleteItem function given in the props
        <button className="destroy"
                onClick={() => this.props.deleteItem(this.props.id)}></button>
      </div>
      <TextInput />
    </li>
  }
};
 ```
 
 重要的一点:实际删除的逻辑还没有实施,这个将是Redux的主要作用.
 在同一个model,我们可以测试和实施下面的特性:
 * 点击checkbox将会调用`toggleComplete`函数
 * 双击条目标签,将会调用`editItem`函数

`test/components/TodoItem_spec.js`
 ```js
  // ...
describe('TodoItem', () => {
  // ...
  it('invokes callback when checkbox is clicked', () => {
    const text = 'React';
    var isChecked = false;
    const toggleComplete = () => isChecked = true;
    const component = renderIntoDocument(
      <TodoItem text={text} toggleComplete={toggleComplete}/>
    );
    const checkboxes = scryRenderedDOMComponentsWithTag(component, 'input');
    Simulate.click(checkboxes[0]);

    expect(isChecked).to.equal(true);
  });

  it('calls a callback when text is double clicked', () => {
    var text = 'React';
    const editItem = () => text = 'Redux';
    const component = renderIntoDocument(
      <TodoItem text={text} editItem={editItem}/>
    );
    const label = component.refs.text
    Simulate.doubleClick(label);

    expect(text).to.equal('Redux');
  });
});
 ```
 
 `src/compoents/TodoItem.jsx`
 ```js
  // ...
render() {
  // ...
  return <li className={itemClass}>
    <div className="view">
      // We add an onClick handler on the checkbox
      <input type="checkbox"
             className="toggle"
             defaultChecked={this.props.isCompleted}
             onClick={() => this.props.toggleComplete(this.props.id)}/>
      // We add a ref attribute to the label to facilitate the testing
      // The onDoubleClick handler is unsurprisingly called on double clicks
      <label htmlFor="todo"
             ref="text"
             onDoubleClick={() => this.props.editItem(this.props.id)}>
        {this.props.text}
      </label>
      <button className="destroy"
              onClick={() => this.props.deleteItem(this.props.id)}></button>
    </div>
    <TextInput />
  </li>
 ```
 
 我们也从`TodoList`组件借助props向下传递`editItem`,`deleteItem`和`toggleComplete`函数.
 `src/components/TodoList.jsx`
 ```js
  // ...
export default class TodoList extends React.Component {
  // ...
  render() {
      return <section className="main">
        <ul className="todo-list">
          {this.getItems().map(item =>
            <TodoItem key={item.get('text')}
                      text={item.get('text')}
                      isCompleted={this.isCompleted(item)}
                      isEditing={item.get('editing')}
                      // We pass down the callback functions
                      toggleComplete={this.props.toggleComplete}
                      deleteItem={this.props.deleteItem}
                      editItem={this.props.editItem}/>
          )}
        </ul>
      </section>
    }
};
 ```
  
## 配置其他组件
现在,你可能对流程有些熟悉了.为了让本文不要太长,我邀请你看看组件的代码,
`TextInput`([相关提交](https://github.com/phacks/redux-todomvc/commit/8550a95fc589ecaa184367bb907c8dfeffc29d2f)),`TodoHeader`([相关提交](https://github.com/phacks/redux-todomvc/commit/cc97354bab0a0369f0c39b34ff24b44084a75ebb)),`Todotools`和`Footer`([相关提交](https://github.com/phacks/redux-todomvc/commit/237dbc36135427f3b5398f19fcc09ecb1e26d895))组件.如果你有任何问题，请留下评论,或着在repo的issue中留下评论.

 你可能主要到一些函数,例如`editItem`,`toggleComplete`诸如此类的,还没有被定义.这些内容将会在教程的下一部分作为Redux actions的组成来定义,所以如果遇到错误,不要担心.
 ## 包装起来
 在这篇文章中,我已经演示了我的第一个React,Redux和Immutable webapp.我们的UI是模块化的.完全通过测试,准备和实际的app逻辑联系起来.怎么来连接？这些傻瓜组件什么都不知道,怎么让我们可以写出时间旅行的app?
 
 [教程的第二部分在这里](http://www.theodo.fr/blog/2016/03/getting-started-with-react-redux-and-immutable-a-test-driven-tutorial-part-2/).
 
 
  
  

  
  