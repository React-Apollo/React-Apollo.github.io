---
title: 摘要|Why use static types in JavaScript? (A 4-part primer on static typing with Flow)
date: 2018-02-12 20:48:38
categories: 技术备忘
tags: [javascript]
---

{{TOC}}

>原文参见[Why use static types in JavaScript](https://medium.freecodecamp.org/why-use-static-types-in-javascript-part-1-8382da1e0adb)

### part one  Flow 的快速介绍

#### boolean
描述`boolean`值
```js
var isFetching: boolean = false;
```

![](https://ws4.sinaimg.cn/large/006tKfTcgy1fodyibtjhoj30wg0dcq37.jpg)

#### number
number 包含了`Infinity`和`NaN`
```js
var luckyNumber: number = 10;

var notSoLuckyNumber: number = NaN;
```

#### string:

```js
var myName: string = 'Preethi';
```

#### null

```js
var data: null = null;
```

#### void

```
var data: void = undefined;
```

#### Array
可以用`Array<T>`描述数组的元素类型, 例如下面
```
var messages: Array<string> = ['hello', 'world', '!'];
```

#### object
可以定义对象的规格:

```js
var aboutMe: { name: string, age: number } = {
  name: 'Preethi',
  age: 26,
};
```

#### function

```js
var calculateArea = (radius: number): number => {
  return 3.14 * radius * radius
};
```


异步函数也可以添加类型
```js
async function amountExceedsPurchaseLimit(
  amount: number,
  getPurchaseLimit: () => Promise<number>
): Promise<boolean> {
  var limit = await getPurchaseLimit();

  return limit > amount;
}
```
### type alias
可以组合现有的类型,创建新的类型
```js
type PaymentMethod = {
  id: number,
  name: string,
  limit: number,
};
```

上面创建了一个新的类型`PaymentMethod`,组合了三个类型

现在可以直接使用了:

```js
var myPaypal: PaymentMethod = {
  id: 123456,
  name: 'Preethi Paypal',
  limit: 10000,
};
```

#### generics

```js
type GenericObject<T> = { key: T };

var numberT: GenericObject<number> = { key: 123 };
var stringT: GenericObject<string> = { key: "Preethi" };
var arrayT: GenericObject<Array<number>> = { key: [1, 2, 3] }
```
创建了一个抽象类型`T`,现在可以用来表示 `numberT`代表`number`类型, 以此类推.
### part two
#### 规范参数和返回值的类型:

```js

const calculateArea = (radius: number): number => 3.14 * radius * radius;
```
#### 带有说明性质

```js
function calculatePayoutDate(
  quote: boolean,
  amount: number,
  paymentMethod: string): Date {
  let payoutDate;
    
  /* business logic */

  return payoutDate;
}
```
很清楚的展示了参数类型,和函数的意图

#### 减少了复杂的错误处理机制代码
有关的错误检查的代码不需要了
```js
const calculateAreas = (radii: Array<number>): Array<number> => {
  var areas = [];
  for (var i = 0; i < radii.length; i++) {
    areas[i] = 3.14 * (radii[i] * radii[i]);
  }

  return areas;
};
```

#### 可以很放心的实行重构

#### 隔离行为和数据

再来看看`calculateAreas`函数

```js
const calculateAreas = (radii: Array<number>): Array<number> => {
  var areas = [];
  for (var i = 0; i < radii.length; i++) {
    areas[i] = 3.14 * (radii[i] * radii[i]);
  }

  return areas;
};
```

首先我们要考虑数据的类型 ,之后才能考虑具体的操作

#### 减少了整整一类的 bugs.

因为远程获取数据是不可靠的, message 有可能没有数据,所以声明数据为?  `maybe`类型
```js
type AppState = {
  isFetching: boolean,
  messages: ?Array<string>
};

var appState: AppState = {
  isFetching: false,
  messages: null,
};
```

#### 减少了单元测试的数量

#### 提供了 domain 模型工具

