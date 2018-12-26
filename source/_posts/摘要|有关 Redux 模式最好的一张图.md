---
title: 摘要|有关 Redux 模式最好的一张图
date: 2018-03-02 05:10:46
categories: Readme
tags: [React,Redux]
---
>今天在 medium 网,看到这篇文章[When do I know I’m ready for Redux?](https://medium.com/dailyjs/when-do-i-know-im-ready-for-redux-f34da253c85f)


![](https://ws1.sinaimg.cn/large/006tNc79gy1foy0b5c2t2g30jg0d7b29.gif)

要点:

- `①`  Redux的单向数据流.  数据只从 Redux=>component. 其实 Redux 也是一个 React 组件, 这个组件的state有特殊的意义. 处理的数据把它转变为 props 就可以传递给子组件了. 这个做法就是 React 的标准模式. 所以如果有一个问题, Redux到底是什么?  它其实也是一个 React 的组件
- `②`  组件的 dispatch 操作, 并没有真正的操作组件里的函数, 只是通过引用赋值,调用了 Redux中定义的 action 函数, 所以这幅图中从组件到Redux并没有直接相连. 这里阐述的很好.



