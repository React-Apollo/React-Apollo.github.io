---
title: 翻译|A Visual Guide to State in React
date: 2019-04-27 09:48
categories: 技术备忘
tags: [React,Redux]
---
[`原文在此:A Visual Guide to State in React`](https://daveceddia.com/visual-guide-to-state-in-react/)
![](https://ws3.sinaimg.cn/large/006tNc79gy1g2gyafgel9j30e8074gmh.jpg)

React的"state"概念是比较难学的内容,不仅仅是因为React中放置了state,而是实际上,React是因此而生存. Redux也和React的state直接相关.
我希望在本文中能把一些困惑的内容讲清楚

## 你一直在使用的这个词...
实际上,这个词"state"有点模棱两可.某种意义上,"state"意思是当前屏幕上的数据表现. 它可以是"loading" 状态,或者是一个"error" 状态. 这里的解释和React里的state解释还不太一样.

从React的角度上,"state"是一个代表了应用中可以变化的部分.每个组件都在`this.state`中保存了自己的state

简而言之,如果需要应用可以做任何事-如果想添加交互,添加和删除内容,输入输出日志-都要包含在state中.

## React的state是什么样子

假设你有这样一个应用,在特定的时间,如下图:
![](https://ws2.sinaimg.cn/large/006tNc79gy1g2gyrr31rij307e0bv74f.jpg)

看这张图,挑出所有可以改变的部分(基本上包含了所有的东西)

![](https://ws1.sinaimg.cn/large/006tNc79gy1g2gyszvl6pj307e0bvaa9.jpg)

现在我们可以给这些内容定义名字(时间,电池用量,室内温度,室外温度),用JavaScript对象描述如下:

```javascript
{
  currentTime: "2016-10-12T22:25:42.564Z",
  power: {
    min: 0,
    current: 37,
    max: 100
  },
  indoorTemperature: {
    min: 0.0,
    current: 72.0,
    max: 100.0
  },
  outdoorTemperature: {
    min: -10.0,
    current: 84.0,
    max: 120.0
  },
  tempUnits: "F"
}
```

这个对象描述了应用的整个state,也就是React state的用途.

注意一点,字段没有和UI完全契合. 没关系,日期很容易格式化,可以用最大值这最小值画出图形的尺度,等等.

这一点保持不变:改变了`state`对象就会改变app的表现.

读者 foobarwtf指出 `min`和`max`不会改变,因为他们从不改变,为什么还要在`state`中出现? 常见的做法是从服务器获取响应输入到state.如果你远程获取当前温度数据,数据就包含了`min`,`max`.最好和state中其他数据一起保存. 因为看起好像数据是固定不变的.但是如何服务器改变了标准怎么处理? 如果用户使用了一个200A的电力系统?等等问题.

所以:state通常保存这个可以变化的东西,也可以放一些从服务器获得的易改变的信息.

## 如何对State进行修改

如果state中任何一项发生变化,例如温度飙升到75°,应用应该刷新反映出变化.这就是React根据state所做的工作:重新渲染整个app

这里是state可能发生变化的原因:
-  用户点击按钮
-  从服务器获得了数据-websocket的信息,或者是之前请求返回的响应数据
-  定时器终止-或许是每5秒更新屏幕上的当前时间

那么,React是如何知道state发生改变的? 持续轮训变化?像Angular一样观察事件?不是,一点也不神奇.

React知晓State的变化是因为你在组件内部通过`this.setState`显式的告诉组件应该怎么更新.换句话说,没有什么魔法,React只是按照你设定的去做更新.

## 计数器中的State变换
上面的家庭检测应用是一个state实战的绝好实例,但是我们会返回简单的"counter"应用,看看state是如何变化的.

这里是counter的工作方式:

- 数字显示从0开始
- 你点击按钮(会调用设定的`handleClick`函数)
- 计数器增加1(调用`setState`完成这个任务)
- React 根据state的变化重新渲染app

![](https://ws1.sinaimg.cn/large/006tNc79gy1g2gzjlghtxj30am0kr0uk.jpg)

## 代码展示

快速浏览:
- React以对象的形式保存state
- 你可以通过调用`setState`来改变对象
- 每次调用`setState`时,React会重新渲染
这里有两个地方要注意:
 - 不能直接用`this.state`,一定要用`this.setState`
 - state的变化时异步的,所以如果你想从`this.state`中立即获取`this.setState`的变化,可能还没有反应出来.

## 用Debugger把代码可视化

![](https://ws3.sinaimg.cn/large/006tNc79gy1g2gy7hz8d3g30cg0ugnd8.gif)
## 细节,细节
在本文中,我说过state是一个描述整个app的单一对象-但是在实际中,它需要分成更小的片段. 最好的方法是把它们保存在"container"组件中,和"presentational"组件隔离. 

如果你正在使用Redux,你实际就有一个描述整个app的大 state对象. Redux的基本做法就是保持一个大的代表整个应用的state, 接着reducer和`mapStateToProps`把它切分成每个组件需要的块.

我希望本文能让你理解state的内容.

