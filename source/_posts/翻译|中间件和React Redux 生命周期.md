
---
title: 翻译|在 react-redux 中使用中间件
date: 2017年3月27日 星期二 中国标准时间 下午2:55:00
categories: 技术备忘
tags: [React,redux]
---


[原文请参看](https://medium.com/@rajaraodv/using-middlewares-in-react-redux-apps-f7c9652610c6#.fu82u8qjf).

>如果你使用过类似Express.js框架构建Node.js程序,你就可能在使用中间件,并且知道他们怎么工作.Redux给前端引入同样的概念.

## 什么是中间件？
中间件是可以被框架自动调用的函数,在框架中数据流结束之前,在数据流中加强或者改变输出.
例如:如果框架里面没有中间件是这个样子的:

`funcA — calls→ funcB — calls→ funcC`

添加了中间件以后,控制流就变为:
`funcA — calls→ funcB — calls→ funcMiddleWare1 — back to →funcB. funcB → then calls→ funcMiddleWare2 — back to→ funcB. funcB — finally calls→ funcC`

注意：funcB最终调用funcC但是在调用funcC之前要调用两个中间件.

## 没有中间件的Redux生命周期

让我们想看看Redux app生命周期,来更好的理解它.

场景:点击”Click Me”按钮,更新”Clicked xyz times” 文本.


![图片1](http://upload-images.jianshu.io/upload_images/2044710-da53be67e7cd17d1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/800)

场景：现在,当用户点击按钮的时候,我们想把点击的数目保存到服务器,并且在debugg中展示state的变化日志.让我们看看现在的控制流.


![图片2](http://upload-images.jianshu.io/upload_images/2044710-196ed4d492237d61.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/800)
在Redux中,中间件函数一个接一个的被调用,直到所有的中间件被调用,然后“Action”对象呗发送到“Reducer”.

注意:这就允许中间件有修改Action对象的潜力,在最终调用Reducers之前,解析AJAX调用,还可以做其他事情比如日志.Reeucers将会更新state,在app需要的时候渲染组件.

## 使用中间件
Redux有个巨大的社区,已经构建了[大量可以完成各种任务的中间件](https://github.com/xgrommx/awesome-redux#react---a-javascript-library-for-building-user-interfaces).

所有你需要做的就是:
1. 通过npm 安装
2. 配置或者添加到Redux

例如：在我前面的blog：[创建React Redux CRUD程序指南](https://medium.com/@rajaraodv/a-guide-for-building-a-react-redux-crud-app-7fe0b8943d0f#.aenutqb0r),app为CRUD操作做AJAX请求.
在里面,我使用AXios的库来做AJAX调用.但是Axios返回一个Promise对象.但是Actions需要传递给Reducers的是一个纯粹的JSON对象.所以在在数据到达Reducers之前使用redux-promise解析Action中的Promise对象.

为了使用,首先安装.

`npm install — save redux-promise`

再做一点配置工作:


```js
 import React from ‘react’;
...
import { createStore, applyMiddleware } from ‘redux’;
import rp from ‘redux-promise’; // <------------ MIDDLEWARE
...
//add middlewares
const createStoreWithMiddleware = applyMiddleware(rp)(createStore);
ReactDOM.render(
 <Provider store={createStoreWithMiddleware(reducers)}>
 <Router history={browserHistory} routes={routes} />
 </Provider>
 , document.getElementById(‘body’));
```
___

## 中间件是怎么工作的？

如果你看了[redux-promise](https://github.com/acdlite/redux-promise),你就可以看到他是怎么工作的.

这里是伪代码:

1. Redux调用中间件,“dispatch(函数)”,“next(函数)”和”action“JSON对象.
2. 中间件检查”action”对象,看看是否有Promise对象
3. 如果没有Promise对象,调用”next“函数返回到Redux.
4. 如果这样做,他会附加上成功或者失败的回调函数,等待服务器的响应.

```
//redux-promise middleware source code
import { isFSA } from 'flux-standard-action';

function isPromise(val) {
  return val && typeof val.then === 'function';
}

export default function promiseMiddleware({ dispatch }) {
  return next => action => {
    if (!isFSA(action)) {
      return isPromise(action)
        ? action.then(dispatch)
        : next(action);
    }

    return isPromise(action.payload)
      ? action.payload.then(
          result => dispatch({ ...action, payload: result }),
          error => dispatch({ ...action, payload: error, error: true })
        )
      : next(action);
  };
}
```
___

更多内容请看:
1. [官方Redux 中间件文档](http://redux.js.org/docs/advanced/Middleware.html)
2. [中间件列表](https://github.com/xgrommx/awesome-redux#react---a-javascript-library-for-building-user-interfaces)
3. 到[A Guide For Building A React Redux CRUD APP](https://medium.com/@rajaraodv/a-guide-for-building-a-react-redux-crud-app-7fe0b8943d0f#.aenutqb0r).

结束


