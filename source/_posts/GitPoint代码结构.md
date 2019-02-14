---
title:  GitPoint代码结构
date: 2019-02-14 09:39
categories: 技术备忘
tags: [React-Native,Redux，styled-compoents]
---

{{TOC}}

 #   GitPoint代码结构 

##  简介 

React的16.8.1的版本已经发布，在稍后的React-Native的0.59版本会支持React-Hooks这个特性。 经过之间一段时间的学习，对React的函数式编程方式有了一定的了解。刚好遇到React-Hooks发布。 学习了一些Hook上的使用方法。由衷的感慨，React向函数式组件的进化让编程变得非常有意思。

之前看过了GitPoint代码，由于代码结构比较复杂，所以似懂非懂的。
又翻出来看，发现GitPoint的技术栈和我之前学习积累的方法已经很接近了。 

**理想的RN技术栈包括如下的技术：**

- React,React-hooks  数据管理
- Functional Components   APP组织
- Apollo    异步操作 GraphQL  client
- Styled-Components  函数式CSS,
- Typescript   类型检查
- React-Navigation 用于导航

**GitPoint目前的技术栈**：

-  React,Redux  数据管理
-  Class Components   APP组织
-  GraphQL,      异步操作 Client
-  Styled-Components   函数式样式
-  Flow    类型检查
-  React-Navigation  导航


> 目的就是想看看从目前的技术栈迁移到理想的技术栈的可行性。
> 对于这个APP,对远程数据的需要比本地的交互操作内容要多得的，
> Redux结构就稍显复杂，但是React-Hooks的useState ,useEffects和useReducer原理和Redux是完全一样的，之前需要把所有的Reducer合并(combineReducer)一起，现在就不用了， 单个的功能组件管理自己的reducer, 如果是全局的state，可以使用useContext方法， 还要两个论坛包装的方法，也可以在全局使用。 原则就是：`‌数据的Immutable`,`数据的单向流动`。 
###   遵循的原则
 1. 数据的Immutable
    现在可以借助新的 Immer 使得 Immutable的操作简单化
 2. 数据单相流动，
     对于函数式组件，完全不是问题，因为 函数式组件的数据天然是通过函数的参数传入。
    

## 项目结构
### 基本结构



 ![](https://ws4.sinaimg.cn/large/006tKfTcgy1g05qzkfrgoj30ji0s4q76.jpg) 

- 🔘 `app.js` :入口文件
- 🔘 `routes.js`: 路由总文件
- 🔘 `root.store.js`: redux的store文件
- 🔘  `root-reducer.js`： redux的reducer的combine文件
- 🔘 `.flowconfig`: flow类型检查的配置文件
- 🔘 `./src` ：程序文件夹

### 入口文件 app.jsx
**`‌静态方法获取当前位置`**

因为GitPoint App支持多种语言的本地化，在这里获取地理位置之后，后面的界面可以加载不同的文字


```jsx
static async initLocale() {
    //获取当前位置
    const locale = await getCurrentLocale();
    //配置当前位置，根据当前位置来设置App本地化信息
    configureLocale(locale);
  }
```

**`constructor`**

 使用`redux-persist` 保存Redux state至本地。在程序启动时需要判读`state`读取是否完成，或者是第一个使用，`state`为`null`.
 

```jsx
constructor() {
    super();

    this.state = {
      rehydrated: false,  
    };
    this.statusBarHandler = this.statusBarHandler.bind(this);
  }
```

**`componentWillMount()`**

在组件挂在周期函数中获取state加密方法，从本地获取state,设置`rehydrated:true` ,标识state加载完毕

```jsx
componentWillMount() {
    const encryptor = createEncryptor({
      secretKey: md5(DeviceInfo.getUniqueID()),
    });

    persistStore(
      configureStore,
      {
        storage: AsyncStorage,
        transforms: [encryptor],
        whitelist: ['auth'],
      },
      () => {
        this.setState({ rehydrated: true });
      }
    );

    this.constructor.initLocale();
  }
```


**`render（）`**

render方法要根据rehydrated的状态加载不同的组件
如果为`false` 加载splash界面

如果为`true`，跳转到React-Navigation的主路由

```jsx
render() {
    if (!this.state.rehydrated) {
      return (
        <Container>
          <Logo source={require('./src/assets/logo-black.png')} />
        </Container>
      );
    }
      //如果已经登录、就返回Redux store包装的主程序界面
      //gitpoint主程序有React-Navigation来执行路由导航任务
    return (
      <Provider store={configureStore}>
        <GitPoint onNavigationStateChange={this.statusBarHandler}>
          <StatusBar />
        </GitPoint>
      </Provider>
    );
    
```














