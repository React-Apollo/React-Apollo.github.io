---
title: 翻译|Thinking Statefully
date: 2019-04-27 12:48
categories: 技术备忘
tags: [React,Redux]
---

[`‌原文:Thinking Statefully`](https://daveceddia.com/thinking-statefully/)

熟练掌握React的过程包含了如何解决特定问题的方法转变.这提醒我,这个学习过程有点像在路上不同的方向开车.
第一次感受这一点是,我真正访问土耳其和卡斯柯岛,他们的车都靠左行驶.在美国我们是靠右行驶,所以要花很大的力气重编程. 一出机场就差点完蛋了.

有意思的是,即使我已经可以在正常的直道上行驶,但是在不同情况发生时,大脑仍然把他转换成了旧的习惯.

转进停车场?习惯接管了,我开进了错误的车道.在停车标志车左转?还是同样的问题.向右转?你认为我已经了解了一切,但是对于我的大脑,完全没这回事.

我讲这个故事是因为在学习React的时候,我的经历是类似的.我想其他人也有这样的经历.

传递props到组件(最好把组件看成是函数),大脑也已习惯了. 看起来和HTML的工作差不多.

在简单实例中,往下传递数据,向上传递事件也很好理解.这就是回掉模式,在其他的地方也很常见.向按钮组件传递一个`onClick` handler是相当普通.

但是如果需要Modal对话框.或者是提示Badge,要怎么操作?亦或者根据事件响应来对一个Icon进行动画操作?可以看到,这些都是命令式的,"事件驱动"的内容在声明式和状态时的React世界显得很不自然.

## 怎么开发"状态式"或者是"声明式"的思考

如果你有jQuery,Angular的经验或者其他框架的以经验,需要调用函数执行任务("过程式编程"),在React的领域里为了更为有效的工作就需要调整思维模型.从实践中可以很快的完成这个转变-只需要给大脑一些新的实例或者"模式".

这里是一些实例

打开/关闭一个Accordion组件(手风琴组件)

**旧有办法**: 点击toggle按钮调用`toggle`函数,从而打开或者关闭accordion.Accordion组件知道该怎么关闭或打开.
**state方法**: Accordion要么是"open"状态,要么是"close"状态. 这个信息我们作为一个标记(flag)存储在Accordion组件的父组件state上(不在Accordion上存储).以名为`isOpen`的prop形式传递state信息,Accordion依据prop来进行渲染. 当`isOpen`是`true`时,渲染为打开,反之就关闭.

```javascript
<Accordion isOpen={true}/>
// or
<Accordion isOpen={false}/>
```

这个实例相对简单.希望不要有什么认知负担. 最大的挑战是以声明式的React方法处理,打开/关闭的state是存储在Accordion组件之外,并以prop的形式传递的.

## 打开,关闭一个Dialog
**‌旧有办法**: 点击按钮打开modal,点击按钮关闭.
**state方法**: Modal是开还是闭是一个状态,"open","state"两者居其一.所以state是"open",我们就渲染组件.如果是"close",就不做渲染.此外,可以给Modal传递`onClose`回调函数-通过这种方法,Modal组件的**父组件**决定了用户点击按钮时应该干什么

```javascript
{this.state.isModalOpen && <Modal onClose={this.handleClose}/>}
```

详细内容请看[Modal Dialogs in React](https://daveceddia.com/open-modal-in-react)

## 提醒组件
**‌旧有办法**: 当一个事件发生时(例如一个错误),调用提示库的组件来显示popup,例如`toast.error("Oh,no!")`

**state方法**: 把提示作为一个state.有0个或者1个,或多个提示,保存在消息数组中. 在根组件处安置提醒组件. 传递state用于显示.你可以用不同的方式来管理消息数组:
-  如果使用Redux,保存在store中,Dispatch actions来添加消息
-  如果不使用Redux,可以保存在根组件的state中,或者是一个单例对象(整个应用中只实例化一次的对象)中.然后就可以传递向组件传递`addNotification`prop,或者导入可以添加到全局单例对象的函数.

 在应用中,你可以使用软件包来完成任务,例如[`react-redux-toastr`](https://github.com/diegoddox/react-redux-toastr).但是概念很简单,所以可以根据你的需求自己编写.
 
 ## 用动画显示改变
 
  假设你有一个有数字的badge用于显示登录的用户,组件从prop获取这个数字.但是如果你想在组件数字变化时有点动效,怎么处理?
  
  **‌老办法**: 可以使用jQuery来toggle(切换)一个执行动画的类([^译注:CSS的类]),或者直接用jQuery操控要执行动画的元素.
  **state方法**: 你可以在props改变时通过`componentWillReceiveProps`声明周期函数比较新旧值来响应变化.如果改变了,可以把"animating" state设置为`true`.接着执行`render`,当"animating"为trur时,添加一个执行动画的CSS类.为false时,不添加类.这里是代码:
  
  ```javascript
  componentWillReceiveProps(nextProps) {
  if(this.props.counter !== nextProps.counter) {
    // Set animating to true right now. When that state change finishes,
    // set a timer to set animating false 200ms later.
    this.setState({ animating: true }, () => {
      setTimeout(() => {
        this.setState({ animating: false });
      }, 200);
    });
  }
}

render() {
  const animatingClass = this.state.animating ? 'animating' : '';
  return (
    <div className={`badge ${animatingClass}`}>
      {this.props.counter}
    </div>
  );
}
  ```


## 完成

