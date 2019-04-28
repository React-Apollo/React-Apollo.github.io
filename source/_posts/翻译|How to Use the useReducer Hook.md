
---
title: 翻译|How to Use the useReducer Hook
date: 2019-04-28 09:20
categories: 技术备忘
tags: [React,Redux,React-Hooks]
---
[原文:`How to Use the useReducer Hook`](https://daveceddia.com/usereducer-hook-examples/)

在所有的[`新React Hooks`](https://daveceddia.com/intro-to-hooks),或许仅仅是因为名字,就可能成为使用最多的一个.
"reducer"这个单词会让很多人联想起Redux-但是读本文,你不必事先理解Redux.

我们这里要谈的"reducer"实际问题是,如何利用`useReducer`的优点来管理组件中的复杂状态(state),新的hook对于Redux意味着什么?Redux需要hook吗?(对不起,有点跑题).

[^译注:结合Redux和useReducer来阐述问题,可能是一个很好的出发点, Redux的reducer和useReducer核心都是根据组件dispatch的Action的type,payload来对State对象进行更新.概念是完全一样的,如果对Redux不是太了解, 可以借助useReducer来理解这个过程. 留给你大脑的转变过程是,如果两者之间的这种相同点存在,可以迁移吗?]

在本文中,我们会探讨一下`useReducer`.在组件中管理复杂state,要比`useState`的方式厉害的多.


## 什么是Reducer?

如果你熟悉Redux,或者数组的`reduce`方法,你就应该知道[`reducer 是什么?`](https://daveceddia.com/what-is-a-reducer/).如果你不熟悉,"reducer"是一个奇特的单词,代表一个函数接收两个值,返回一个值.

如果有一个数组, 你想把其中的元素组合成单个值,"函数式编程"的做法是使用数组的`reduce`函数. 例如,如果你有一个数组,元素是数字,你想得到数字的综合, 可以编写一个reducer函数,传递给数组的`reduce`方法,例如:

```javascript
let numbers = [1, 2, 3];
let sum = numbers.reduce((total, number) => {
  return total + number;
}, 0);
```

如果之前没看过这样的用法,可能有点晕. 这里所做的是针对数组的每个元素调用函数,传递的参数是前一个`total`和当前的`number`.函数返回值成为新的`total`,第二个传递给`reduce`的参数(在这里是0)就是`total`的初始值. 在这个例子中,输入的函数将会调用三次:

-  用个(0,1)调用,返回`1`
-  用个(`1`,2)调用,返回3
-  用个(`3`,3)调用,返回1
-  `reduce`返回6,结果存储在`sum`中.

### 但是,这和useReducer有什么关系?
我花了半页的篇幅俩解释数组的`reduce`的原因是因为,`useReducer`接受相同的参数,基础的工作是相同的.你传递一个reducer函数和初始值(initial state). reducer接收当前的`state`和一个`action`,返回一个新的state.我们可以写一个类似的合计reducer:
```javascript
useReducer((state,action)=>{
 Return state+action;
},0)
```

那么如何触发这个操作? `action`是如何输入函数的. 想到这个问题就对了.

[^译注:这里的这个问题绝对是学习Redux时,令人最困惑的地方]

`useReducer`返回有两个元素的数组,类似useState hook. 第一个元素是当前的state,第二个参数是`dispatch`函数. 实际的代码如下:

```javascript
const [sum, dispatch] = useReducer((state, action) => {
  return state + action;
}, 0);
```

注意"state"可以是任何值,不一定非要是一个对象. 可以是数字,数组,任何东西. 

接着来看一个使用reducer的完整组件实例:

```javascript
import React, { useReducer } from 'react';

function Counter() {
  // 首次渲染会创建一个state,后续的渲染会保存结果.
  const [sum, dispatch] = useReducer((state, action) => {
    return state + action;
  }, 0);

  return (
    <>
      {sum}

      <button onClick={() => dispatch(1)}>
        Add 1
      </button>
    </>
  );
}
```

可以在[`CodeSandbox`](https://codesandbox.io/s/38k7m72yk6) 试试

可以看到,点击按钮,dispatch一个`action`,参数是1, 这个值会被加到当前的state上, 之后组件会用新的state(更大的值)来渲染组件.

我可以的把"action"写成这样.没有使用`{type:"INCREMENT_BY",value:1}`的形式或者其他类似Redux的形式,因为reducer不一定必须要准守Redux的type模式.Hooks的世界是一个全新的世界:这一点很值得考虑,是否能发现旧有模式的价值,并保持它们,还是使用新的模式.

## 稍微复杂一点的例子

现在来看一个和典型[`Redux reducer`](https://daveceddia.com/what-is-a-reducer/) 非常接近的实例.我们要创建一个组件管理购物车列表,同时也会使用另一个hook:`useRef`

首先导入两个hook:

```javascript
import React,{useReducer,useRef} from 'react'
```

接着创建组件,设置ref和reducer.ref保留对表单输入的引用,便于我们获取表单的值(也可以通过组件内部state,传递`value`,`onChange` props来获取值,但是用useRef可以很好的展现它的用法)

```javascript
function ShoppingList() {
  const inputRef = useRef();
  const [items, dispatch] = useReducer((state, action) => {
    switch (action.type) {
      // do something with the action
    }
  }, []);

  return (
    <>
      <form onSubmit={handleSubmit}>
        <input ref={inputRef} />
      </form>
      <ul>
        {items.map((item, index) => (
          <li key={item.id}>
            {item.name}
          </li>
        ))}
      </ul>
    </>
  );
}
```

注意,本例中的"state"是一个数组.我们使用一个空数组来初始化它,(传递给`useReducer`的第二个参数),后续会从reducer函数返回一个数组.

### useRef Hook

题外话解释一下`useRef`的用法,之后在返回reducer话题.

`useRef`hook 可以让我们创建一个DOM元素的持久化引用. 调用`useRef`会创建一个空的引用(可以传递参数进行初始化).返回的对象有一个`current`属性,所以在实例中,我们可以通过`inputRef.current`来访问DOM元素的输入值. 如果你对`React.createRef()`很熟悉,这里的工作原理是相同的.

从`useRef`返回的对象不仅仅可以承载一个DOM元素的引用,它可以承载做组件内的任何特定值,并且在渲染中保持固定.耳熟! 必须的.

`useRef`也可用于创建泛型实例化变量,和React 类组件中的`this.whatever=value`做法一样. 唯一的区别是要写成"side effect"的形式,所以就不能在组件渲染过程中改变它了-只能在`useEffect`内部执行. [`官方Hook问答`](https://reactjs.org/docs/hooks-faq.html#is-there-something-like-instance-variables) 有实例讲解.

### 回到useReducer的例子

用`from `包装`input`,在按下Enter键时触发提交函数. 现在需要编写`handleSubmit`函数,认为是把一个项目添加到列表上,还要在reducer中处理action

```javascript
function ShoppingList() {
  const inputRef = useRef();
  const [items, dispatch] = useReducer((state, action) => {
    switch (action.type) {
      case 'add':
        return [
          ...state,
          {
            id: state.length,
            name: action.name
          }
        ];
      default:
        return state;
    }
  }, []);

  function handleSubmit(e) {
    e.preventDefault();
    dispatch({
      type: 'add',
      name: inputRef.current.value
    });
    inputRef.current.value = '';
  }

  return (
    // ... same ...
  );
}
```

reducer函数有两个分支: 一个是action:`type==='add'`,`默认`分支:其他的任务.

当reduce获取到"add" action 以后, 它会返回一个新的数组包含了旧的元素,在末尾添加新的一条项目.

我们使用数组的长度作为自增ID.在这个实例中用自增ID是可以的,但是在实际的app中,不太理想,因为有可能导致重复的ID和bugs(最好是使用类似[`uuid`](https://www.npmjs.com/package/uuid)的软件包,或者由服务器生成一个唯一的ID!)

在用户点击Enter键时,会调用`handleSubmit`函数,所以需要调用`preventDefault`来避免正页面的重载. 之后调用`dispatch`,参数是action.在app中,我们想让action更像Redux形式-拥有`type`属性,附带一些数据. 此外还有清除输入.

这个阶段的代码[`CodeSandBox`](https://codesandbox.io/s/k2vqn76qmr)

### 移除一项

现在添加从列表中移除项目的能力

挨着项目添加 删除按钮,点击时会dispatch一个action,参数是`type==="remove"`,需要删除项目的索引

接着需要在Reducer中处理action,通过过滤数组来移除项目

```javascript
function ShoppingList() {
  const inputRef = useRef();
  const [items, dispatch] = useReducer((state, action) => {
    switch (action.type) {
      case 'add':
        // ... same as before ...
      case 'remove':
        // keep every item except the one we want to remove
        return state.filter((_, index) => index != action.index);
      default:
        return state;
    }
  }, []);

  function handleSubmit(e) { /*...*/ }

  return (
    <>
      <form onSubmit={handleSubmit}>
        <input ref={inputRef} />
      </form>
      <ul>
        {items.map((item, index) => (
          <li key={item.id}>
            {item.name}
            <button
              onClick={() => dispatch({ type: 'remove', index })}
            >
              X
            </button>
          </li>
        ))}
      </ul>
    </>
  );
}
```

这个阶段的代码[`CodeSandBox`](https://codesandbox.io/s/ywmwzq26w9)

### 练习:清除列表
在额外添加一个内容,清空列表的按钮,作为练习.

在`<ul>`之上添加一个按钮, 添加`onClick`属性,可以dispatch,type为"clear"的action.之后在reducer中添加分支处理"clear"action.



## 那么... Redux就此终结篇章了吗?

很多人初次看到`useReducer`就想,React现在内置reducer了,还有Context可以在全局范围传递数据,所以Redux已死! 我想给出我的一些想法,因为我猜你也很想知道到Redux的命运将会如何?

[^译注: 我个人观点, useReducer的引入不仅不会让Redux很难堪,反而会让程序员借助useReducer对Redux有更深的认识,Redux的构架学习可能会有很多的回报,此刻如果舍弃React-Native,投入flutter的怀抱, flutter-Redux的就不再是一个负担了.]

我不认为`useReducer`会杀死Redux,`Context`也不会. 我认为这两个方法只是扩展了React state管理的方法范围而已,所以真正的情况是他们会减少使用Redux的用例.

Redux仍然比Context+`useReducer`所做的工作多得多- Redux有Redux DevTools用于拍错,可以定制化的组件,还有[`全生态系统的助手软件包`](https://github.com/markerikson/redux-ecosystem-links).你可以大胆的说,Redux在很多情况下都有点杀鸡用牛刀.但是我认为它仍然是非常强有力的.

Redux提供的`全局`store可以让你集中控制app的data.`useReducer`是特定组件私有的.使用`useReducer`,`useContext`构建一个迷你版的Redux也是完全可行的. 如果你想做,它们完全可以满足需求(Twitter上有很多人已经做了,有截图).我个人仍然想念DevTools. 

总之-Redux活蹦乱跳的.Hooks不会让Redux过时. 

## 自己尝试一下

一下是几个小的应用,可以用`useReducer`hook来完成

-  建一所房子,有一盏灯,按按钮可以调光-关,低亮度,中等亮度,最高亮度
-  做一个键盘锁,有6个按钮, 正确的顺序会解锁. 真确的按键顺序事先记录在state中, 顺序不正确会充值.





