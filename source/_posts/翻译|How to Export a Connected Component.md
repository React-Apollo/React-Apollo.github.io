---
title: 翻译|How to Export a Connected Component
date: 2019-04-27 09:13
categories: 技术备忘
tags: [React,Redux]
---

[原文在这里:`How to Export a Connected Component`](https://daveceddia.com/redux-connect-export/)

根据你在`export`的不同,可以获得一个完美的函数式React-Redux connected组件,或者是一个完全忽略Redux的组件

换句话说这里两个完全不同的世界:

```javascript
class Thing extends Component { ... }

export default connect(mapStateToProps)(Thing);
```

还有这个:

```javascript
export class Thing extends Component { ... }

connect(mapStateToProps, mapDispatchToProps)(Thing);
```

如果设定为第二个实例,可以注意到所有的React有关的东西,但是Redux的函数,`mapStateToProps`和`mapDispatchToProps`没有返回

## `connect`不会对组件作出改变

在你用connect包装一个组件的时候, 例如`connect(...)(Thing)`,重要的一点要理解,虽然返回的是一个connected的组件,但是它根本没有动过原始的Thing组件任何东西.

换句话说,运行`connect(...)(Thing)`,没有"connect"到`Thing`组件,缺失没有. 所做的是翻译一个经过连接的新组件.

## 导出Connected组件
所以,在导出组件的时候,一定要定义到底连接的是哪一个组件.确保`export`关键字出现在 `connect`调用的前面,像这样:

```javascript
export default connect(...)(Thing);
```

## 为什么不同时导出原始组件和经过连接的组件?
同时导出连接组件和未连接组件非常有效.对于测试大有好处-例如想测试没有没有连接到模拟Redux store的组件.

下面是同时导出未连接组件和连接组件的代码:

```javascript
export class Thing extends React.Component {
  render() {
    return "whatever";
  }
}

const mapState = state => ({ someValue });
const mapDispatch = { action1, action2 };

export default connect(mapState, mapDispatch)(Thing);
```

注意这里有两个导入,其中之一是名字,另一个是default,这里的定义很重要,因为会影响到后面的导入(import).

## Import 连接组件
总的原则是,如果某个代码是用`exprot default`,在导入的时候不用`{}`,;例如:

```javascript
// Thing.js
export default connect(...)(Thing);

// UserOfThing.js
import Thing from './Thing';
```

如果导出的是名字,需要使用`{}`:

```javascript
// Thing.js
export function Thing() { ... }

// UserOfThing.js
import { Thing } from './Thing';
```




