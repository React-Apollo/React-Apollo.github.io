---
title: 翻译|Immutability in React and Redux/ The Complete Guide News Clone
date: 2019-04-23 11:50
categories: 技术备忘
tags: [React,Redux]
---

[原文在这里:Immutability in React and Redux: The Complete Guide](https://daveceddia.com/react-redux-immutability-guide/)

> Immutability(不可突变性,一下直接使用英文)是一个令人困惑的话题,总体上在React,Redux和Javascript出现的地方都会有他的身影浮现.

  在React组件没有自动渲染的时候,你可能碰到了一个bug,即使是你知道已经修改了props,并且有人会提醒你,应该要做immutable state更新.或许你或者同事之一经常写出mutate(与immutable对应,为可突变,一下沿用英文单词)state的 Redux Reducer.你不得不经常纠正他们(reducers,或者同事).
  
  这一点有点诡异,也十分的微妙,尤其是你不确定要到底要注意什么.坦率讲,如果你没有认识到Immutable的重要性,就很难关注它.
  
  这个教程会解释什么是immutability以及如何在应用中编写immutable代码.一下是涵盖的内容:

{{TOC}}  
  
## 什么是Immtablity?

首先 immutable是mutable的反义词-mutable的意思是:变化,修改,能被搞得一团糟.

所以如果某个东西是immutable,那么他就是不能有变化的.

极端的例子是,不能使用传统意义的变量, 你要不断的创建新值来代替旧的值. JavaScript没有这么极端, 但是有些语言根本不允许mutate任何东西(Elixir, Erlang还有ML).

Javas不是纯粹的函数式语言,它可以在某种程度上伪装成函数式语言.JS中有些数组操作时immutable(意思是:不修改原始值,而是返回一个新的数组).字符串操作总是immutable的(JS使用改变的字符串创建新的字符串). 同时,你也可以编写自己的immutable函数.需要注意的是要遵守一些规则.

## 用于Mutation的实例代码

现在来看看mutality是如何工作的. 从整个`person`对象开始:

```javascript
let person = {
	firstName: "Bob",
	lastName: "Loblaw",
	address: {
		street: "123 Fake St",
		city: "Emberton",
		state: "NJ"
	}
}
```

接着假设写一个函数赋予person超凡的力量:

```javascript
function giveAwesomePowers(person) {
	person.specialPower = "invisibility";
	return person;
}
```

好了,每个人都获得了超集能力. 隐身(invisibility)是很腻害的技术

现在让我们给Mr.Loblaw其他一些特别的能力

```javascript
// Initially, Bob has no powers :(
console.log(person);

// Then we call our function...
let samePerson = giveAwesomePowers(person);

// Now Bob has powers!
console.log(person);
console.log(samePerson);

// He's the same person in every other respect, though.
console.log('Are they the same?', person === samePerson); // true
```

这个函数`giveAwesomePowers` mutate 了传递进入的`person`对象. 运行这个代码,你会看到第一次打印出的`person`,Bob没有`specialPower`属性.但是接下来,第二次,他突然就有了`specialPower`能力.

问题在于,因为这个函数修改了传递进入的`person`,我们再也不知道之前的对象是什么样子.这个对象永远被改变了.

从`giveAwesomePowers`函数返回的对象和我们传递进的对象是同一个对象,但是在对象的内部已经乱套了.属性已经发生改变. 因此对象被mutate了(突变了).

我想要再次重申一下,因为这一点很重要:对象的**内在** 已经发生改变,但是对象的引用没有变[^译注:在内存中的地址空间没变].从对象外部看是同一个对象(全等于检查例如`person===samePerson`为`true`,就是这个原因.)

如果我们想让`giveAesomePowers`函数不对person对象作出修改,必须要作出一些改变.首先要让函数变 *pure*(变纯),因为纯函数和immutability紧密相关.

## Immutability的原则

为了让函数变纯,必须要遵守以下规则:

1. 相同的输入总是有相同的返回值.
2. 纯函数不能有副作用(side effect) [^译注:总是觉得这个副作用不太明了,用附带作用是不是更好理解一点?]

## 那么什么是"Side Effect(副作用)"?

"Side effects"是一个宽泛的术语,但是本质上,意味着此刻调用的函数还修改了作用域之外的内容.看看一些side effect的例子...
- 突变/修饰了输入的参数,像`giveAwesomePowers`函数所做的
- 修改任何函数以外的其他state,例如修改了全局变量,或者`document.(anything)`或者`window.(anything)`
- 执行API调用
- `console.log()`
- `Math.random()`

  API调用可能让你觉得很迷糊.毕竟调用API,例如`fetch('/users')` 好像完全没有改变UI中的任何东西.
  
  但是在深究一下:如果你调用`fetch('/users')`,能改变其他的东西吗?甚至是在UI之外?
  
  非常明确.API调用会产生一条浏览器的网络日志.也会创建(有可能最终会关闭)一个指向服务器的网络连接. 一旦调用命中服务器,一切都有可能发生. 服务器可以做任何想做的事,包括继续调用其他的服务,作出更多的mutation操作. 最终,API调用会在某个地方生成一个日志文件(生成日志文件是正正整整的mutation操作).
  
  
   所以想我说的一样,"side effect"的确是涵盖宽泛的术语. 下面是一个没有side effect的函数:
   
```javascript
function add(a, b) {
  return a + b;
}
```

你调用一次和调用一百万次一个样, 世界上其他地方的东西不会发生任何改变. 我意思是,从技术角度,严谨一点,在你调用这个函数时,世界上其他的东西会改变的. 时间会流逝...强大帝国会衰落...但是调用这个函数不会直接的导致外接其他事物发生变化.这一点满足规则2-没有side effect

再者, 没有调用这个函数,例如 `add(1,2)`,你总是会得到相同的返回结果.不管你调用多少次. 这一点满足规则1-同一输入==同一响应

## JS 数组方法会导致Mutate

几个特定的方法会在使用的时候导致数组发生mutate,

- push(在一个数组末尾添加一个元素)
- pop(从数组的末尾移除一个元素)
- shift(从数组的开始处移除一个元素)
- unshift(在数组的开始处添加一个元素)
- sort
- reverse
- splice

 注意,JS 数组的`sort`操作是mutable的,它会在原内存地址空间上进行排序操作(in place,或者叫原位操作).要改为immutable操作([^译注:这一点,似乎原作者没有明确表达?]).可以拷贝一份,然后针对拷贝进行操作.可以使用一下的几个方法进行操作:
 
 ```javascript
 let a = [1, 2, 3];
let copy1 = [...a];
let copy2 = a.slice();
let copy3 = a.concat();
 ```
 
所以,如果你想对一个数组进行immutable的排序操作, 可以这么操作

```javascript
let sortedArray = [...originalArray].sort(compareFunction);
``` 


关于`sort`方法有个小知识点(过去困扰过我), 传递给`sort`的`compareFunction`需要返回0,1或者-1.不能是布尔值.下次编写比较函数时要留意这一点.

## 纯函数只能调用其他的纯函数

一个可能出问题的地方就是在纯函数中调用了不纯的函数.纯度是可以变化的.要么有要么就没了.你可以写一个完美的纯函数,但是如果你最后点用了一个其他的函数,这些函数又调用了`setState`,`dispatch`,亦或者其他的side effect操作, 纯函数就不存在了.

现在有一些几个特例的side effect是可以"接受的".使用`console.log`输出日志是可以接受的. 是的,从技术角度上讲, 这是一个side effect,但是它不会影响任何其他内容.

## 纯函数版的 `giveAwesomePowers`

现在谨记纯函数的原则,重写这个函数

```javascript
function giveAwesomePowers(person) {
  let newPerson = Object.assign({}, person, {
    specialPower: 'invisibility'
  })

  return newPerson;
}
```

现在稍微有点不同,并没有修改person对象,我们创建了一个 new  person对象.

如果之前你没见过`Object.assign`,它的用法是把一个对象的属性复制到另一个对象中. 你可以传递多个对象,`Ojecct.assign`会把多个对象按照从左到右的方向合并成一个单一对象,因此会覆盖重复的属性.(说到从左至右,我意思是执行`Object.assign(result,a,b,c)`,)会把`a`拷贝进`result`,接着是`b`,接着是`c`)

但是`Object.assign()`不会执行深度融合操作-只有每个参数对象的的直接子代属性才能够被移动.也就是时候, 非常重要的一点,这个操作不会拷贝或者克隆参数对象的属性. 它会按照原来的样子分配, 引用不会动.

所用上面的代码所做的是创建了一个空对象,接着把所有的`person`的属性复制到空对象,接着把`specialPower`属性也复制的空对象中.另一种可以执行相同操作的方法是对象在展开操作(spread operator):

```javascript
function giveAwesomePowers(person) {
  let newPerson = {
    ...person,
    specialPower: 'invisibility'
  }

  return newPerson;
}
```
对象展开操作可以这么理解:"创建一个新对象,之后从`person`插入属性`person`,接着插入另一个属性`specialPower`".上面的写法里的对象展开语法是JavaScript规范ES2018的正式组成部分.

## 返回全新对象的纯函数

现在我们可以使用新的纯函数版的`giveAwesomePowers`来重新运行之前的实例代码.

```javasccript
// Initially, Bob has no powers :(
//打印原始对象
console.log(person);

// 执行纯函数版的对象修改操作
var newPerson = giveAwesomePowers(person);

// Now Bob's clone has powers!
console.log(person);
console.log(newPerson);

//  newPerson 是一个全新的对象了
console.log('Are they the same?', person === newPerson); // false
```


最大的不同点是,`person`对象没有被修改. Bob没有改变. 函数用同样的属性创建一个Bob的克隆版本,此外还具有了隐身的属性.

这就是函数式编程很另类的地方. 对象不断的被创建和销毁. 我们不能修改Bob;只能创建克隆,修改克隆,然后用克隆版本替代Bob.真的有点残酷.如果你看过电影 致命魔术(The Prestige),有点类似(如果没看多,就当我没说).

## React优先考虑Immutability

在React的用例中, 绝对不要mutate state或者props是很重要的.不管是函数式组件或者类组件都要遵循这一原则. 如果你准编写类似这样的代码`this.state.something=...`或者`this.props.something=...`,不要这么做了吧, 试试看更好的方法.

要修改state,唯一的方法就是使用`this.setState`.如果你很好奇为什么要这么做,可以看看这篇文章[`why not to modify state directly`](https://daveceddia.com/why-not-modify-react-state-directly/).

至于props,是单向流动的.Props输入进组件.Props不是双向通道,至少不能通过mutate操作把props设定为新的值.

如果你必须要发送一些值返回到父组件中,或者要触发父组件中的某些操作, 可以以props的形式传递函数来实现,之后在需要的时候通过在子组件内调用函数来和父组件通讯. 下面是就是回调prop的实例:

```javascript
//子组件
function Child(props) {
  // 如果,点击按钮
  // 会调用从父组件通过props传递的函数.
  return (
    <button onClick={props.printMessage}>
      Click Me
    </button>
  );
}
//父组件
function Parent() {
  //①父组件中定义一个函数
  function printMessage() {
    console.log('you clicked the button');
  }

  // ②父组件通过props向子组件传递一个函数
  // 注意!!!: 传递的是函数名,不是调用结果
  // 是printMessage, 不是 printMessage()
  return (
    <Child onClick={printMessage} />
  );
}
``` 

[^译注:这个示例代码如果不太明白,要反复的看,这是Redux最核心思想之一].

## Immutability 对于PureComponents至关重要.

默认情况下,React组件(函数式组件或者通过继承React.component的类组件)在他们的父组件重新渲染时也会重新渲染,或者在组件内部通过`setState`修改内部state时也会重新渲染.

从性能角度考虑,优化React组件最简单的办法是声明一个类,继承`React.PureComponent`,不要继承`React.Component`.这样做,只有在组件的props或者state改变时才会重新渲染. 再也不会在父组件重新渲染时,没头没脑的跟着重新渲染了.只有在自己的props发生变化时才执行重渲染.
这里是React依赖immutability的原因:如果你要向`PureComponent`传递props,必须要确保这些props是通过immutability的方式更新的.意思是说.如果props是对象或者数组,一定要用新的(修改过的)对象或者数组来替换整个props值.像之前对Bob做的一样-把他杀掉,然后用克隆顶替.

如果你通过修改属性,或者添加新的项目来修改对象或者数组的内部元素,甚至是修改数组元素内部的结构- 修改之后的对象或者数组会引用全等于旧的自身,`PureComponent`就不会注意到props的变化,不会重新渲染. 怪异的渲染问题就会接踵而来.

还记得第一个实例中的Bob和`giveAwesomePowers`函数吗? 还记得由函数返回的对象如何与`person`相同吗?用的是三个等号,`===`. 原因是两个对象的引用地址都指向同一个对象. 内部发生改变了,但是地址没有变.

## JavaScript中引用全等于是如何工作的?

什么是"引用等于"(referentially equal)?好吧,有点离题,但是理解这个概念非常重要.

JavaScript的对象和数组都存储在内存中(现在,你应该立刻点头,否则就很难解释下去了).

我们假设内存像一个盒子,变量名"指向"这个盒子, 盒子里放的是实际的值.


![](https://ws3.sinaimg.cn/large/006tNc79gy1g2bjdjd7o2j310k0u0myy.jpg)

在JavaScript中,这些盒子(实际就是内存地址)是没有名字,或者不为人所知的. 你不会知道一个变量指向的内存地址(在某些语言中,例如C语言,你可以实际查看一个变量的内存地址,看看他们的生存情况.)

如果你声明一个变量,它会指向新的内存地址.

![](https://ws1.sinaimg.cn/large/006tNc79gy1g2bjeri62jj30u012q42s.jpg)

如果你mutate了变量的内部结构, 它仍然指向同一个地址.

![](https://ws3.sinaimg.cn/large/006tNc79gy1g2bjh616p8j30uk0u0n0a.jpg)

有点类似于扒掉了房子中的一切东西,重新修了墙,厨房,起居室,游泳池等等--- 房子的地址没有改变. 

**‌关键点:** 当我们用`===`比较两个对象或者数组时,JavaScript实际比较的是他们指向的内存地址-也就是引用(references).JS甚至根本都不看对象.它只比较引用. 这就是"引用等于"(referential equality)的意思.

所以,如果你接收一个对象,修改它时,修改的是内容,但是不会改变它的引用.

另一点是,在你把一个对象赋值给另一个对象(或者作为函数参数传递,这么做更高效),其他的对象仅仅是指向第一个对象的地址.有点想巫毒娃娃.你在第二个对象上做的事会直接影响到第一个对象.


下面的代码让你更清楚的认识到这个问题.

```javascript
// 创建变量 `crayon`,指向一个盒子 (无名),
// 盒子承载了对象 `{ color: 'red' }`
let crayon = { color: 'red' };

// 改变 `crayon` 的属性 不会改变他的指向 
crayon.color = 'blue';

// 把对象或数组赋值给一个新的变量
// 新变量不会改变旧变量指向的盒子
let crayon2 = crayon;
console.log(crayon2 === crayon); // true.两者指向同一个盒子
// 任何针对 `crayon2`变量的修改 也会影响到变量 `crayon1`
crayon2.color = 'green';
console.log(crayon.color); //变为绿色!
console.log(crayon2.color); //也是绿色了!

// 因为这两个变量指向同一个内存地址
console.log(crayon2 === crayon);
```

## 为什么不做深等于检查?
在声明两个对象之前检查两个对象的内部,看起来更合乎情理.这是事实,但是这样做速度很慢.

到底有多慢? 这要看你需要比较的对象.比较有10,000个子属性和孙子属性的对象肯定比2个属性的对象慢.时间无法预测.

引用等于的的时间,计算机科学家成为"时间常数"(constant time).
时间常数也成为 O(1),意思是操作的花费时间总是相同,不用考虑输入值有多大.

深度等检查,成为线性时间(linear time), O(n).意思是花费的时间和对象中的键成比例. 通常来说, 线性时间总是比时间常数慢.

这样来思考:假设JS每次比较两个值例如`a===b`要花费0.5秒时间.现在你是愿意进行引用检查还是深入两个对象比较每对属性?听起来几很慢.

在实际计算中,等检查比时间要远远低于1秒,但是尽肯能的少做工作在这里也是适用的.其他条件相同,有限考虑性能. 在试图找到应用的瓶颈时,这会节省大量时间.如果你留心一一点,刚开始就不会慢.

`const`会阻止改变吗?

简短的回答是:不能阻止. `let`,`const`,`var`都不会阻止你改变对象的内部结构.所有这三种声明方式都允许你mutate对象或数组的内部结构.

"但是它不是叫做`const`吗"? 难道意思不是 constant(恒定)?

好吧! `const` 只会阻止你重新赋值引用,但是不会阻止你改变对象内部结构. 实例如下:

```javascript
const order = { type: "coffee" }

// const will allow changing the order type...
order.type = "tea"; // this is fine

// const will prevent reassigning `order`
order = { type: "tea" } // this is an Error
```

下次遇到`const`要留点心.

我喜欢使用`const`提醒我自己一个对象或者数组不应该被mutate(大多数情况下),如果我在编写代码时,我确定要修改某个对象或者数组,我会用`let`声明. 这像是一个传统(像其他传统一样,如果你时不时的打破约定,就不太好了).

## 怎么更新 Redux的State

Redux需要保证它的reducer是纯函数. 意味着你不能直接修改state-必须基于旧的对象创建一个新的state,正如我们上面对Bob做的那样(如果你不太确定,可以看看这篇文章 [`what a reducer is`](https://daveceddia.com/what-is-a-reducer/),介绍了reducer名字的来历)

编写代码对state作出immutable更新有点棘手. 下面你会看大一下常见的模式

不管是在浏览器终端,还是实际的应用中亲自尝试一下. 尤其要注意嵌套对象的更新,实践中也是如此. 我发现嵌套对象是最麻烦的.

所有这些模式对于React state同样也是适用的.所以在这个教程中学到的东西可以用于Redux,没有Redux的应用也可以用.

在最后部分,会看到使用Immer库[`让操作更简单`](https://daveceddia.com/react-redux-immutability-guide/#easy-state-updates-with-immer). 但是不要直接跳到最后一部分.理解普通的编写方式对于明白具体的工作原理大有好处.

## `...` 展开操作符

这些事例大量使用了**展开**操作符针对数字和对象进行操作. 下面是具体的工作方式

`...`放在对象或者数组之前,它解开内部的子元素,插入到右边的变量中

```javascript
// For arrays:
let nums = [1, 2, 3];
let newNums = [...nums]; // => [1, 2, 3]
nums === newNums // => false! 新的数组对象

// For objects:
let person = {
  name: "Liz",
  age: 32
}
let newPerson = {...person};
person === newPerson // => false! 新的对象


// 内部属性不动 :
let company = {
  name: "Foo Corp",
  people: [
    {name: "Joe"},
    {name: "Alice"}
  ]
}
let newCompany = {...company};
newCompany === company // => false! 不是同一个对象 object
newCompany.people === company.people // => true! 内部属性相同
```

像上面一样使用, 展开操作符使得创建包含相同内容的数组和对象变得更容易.在创建一个对象/数组的拷贝是非常有用,接着我们可以重写需要改变的部分:

```javascript
let liz = {
  name: "Liz",
  age: 32,
  location: {
    city: "Portland",
    state: "Oregon"
  },
  pets: [
    {type: "cat", name: "Redux"}
  ]
}

//使Liz年龄增加一岁,其他的都不动
let olderLiz = {
  ...liz,
  age: 33
}
```

展开操作符是ES2018标准的一部分.

## 更新State的方法

这些例子的编写出发点是从Redux reducer中返回state. 我会展示输入的state是什么样子, 返回的Sate是什么样的.

为了保持实例代码简洁. 我会完全忽略"action"参数. 假定更新可以有任何action触发. 当然在你自己的reducer中, 你可能会私用`switch`和`case`来针对每个action执行操作,但是我认为这会增加本部分理解的噪音.

### 在React中更新State

为了在简单的React  State中使用这些事例, 需要稍作一些调整.

因为React会 *浅融合*传递进`this.setState()`的对象.不需要像Redux一样展开已有的state.

在Redux reducer中,要这么写:

```javascript
return {
  ...state,
  (updates here)
}
```

对于简单 React,可以这么写, 不需要展开操作符:

```javascript
this.setState({
  updates here
})
``` 

要记住一点,尽管`setState`不会执行浅融合,在更新state内嵌套的属性时也必须要使用展开操作符(任何比第一层更深的部分).

## Redux:更新一个对象
当你想更新Redux state的顶层属性时,用`...state`拷贝存在的state,之后列出要更新的属性和对应的修改值

```javascript
function reducer(state, action) {
  /*
    State 类似这样:

    state = {
      clicks: 0,
      count: 0
    }
  */

  return {
    ...state,
    clicks: state.clicks + 1,
    count: state.count - 1
  }
}
```


## Redux:更新对象内的对象
(这一部分并不是专门针对Redux的-对用简单的React state通用适用  [`看这里,如何使用`](https://daveceddia.com/react-redux-immutability-guide/#updating-state-in-react)).

当你想更新的对象在Redux内部一层,或更底层,需要拷贝每一层,直至包含了需要更新的对象部分.这里是第一层实施:

```javascript
function reducer(state, action) {
  /*
    State像这样:

    state = {
      house: {
        name: "Ravenclaw",
        points: 17
      }
    }
  */

  //  Ravenclaw加2分
  return {
    ...state, // 拷贝(level 0)
    house: {
      ...state.house, // 拷贝嵌套的 (level 1)
      points: state.house.points + 2
    }
  }
```

另一个例子, 有两层深度:

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = {
      school: {
        name: "Hogwarts",
        house: {
          name: "Ravenclaw",
          points: 17
        }
      }
    }
  */

  // Two points for Ravenclaw
  return {
    ...state, // 拷贝 (level 0)
    school: {
      ...state.school, // 拷贝 level 1
      house: {         // 替换
      state.school.house...
        ...state.school.house, // 拷贝存在属性        points: state.school.house.points + 2  // 改变属性值
      }
    }
  }
```

在更新深度嵌套的对象时,这个代码很难阅读.

## Redux:通过对象的键来更新对象

```javascript
function reducer(state, action) {
  /*
    State looks like:

    const state = {
      houses: {
        gryffindor: {
          points: 15
        },
        ravenclaw: {
          points: 18
        },
        hufflepuff: {
          points: 7
        },
        slytherin: {
          points: 5
        }
      }
    }
  */

  // Add 3 points to Ravenclaw,
  // 变量存储键名
  const key = "ravenclaw";
  return {
    ...state, // copy state
    houses: {
      ...state.houses, // copy houses
      [key]: {  //利用计算属性修改键值
        ...state.houses[key],  // copy that specific house's properties
        points: state.houses[key].points + 3   // update its `points` property
      }
    }
  }
```

## Redux: 在数组前添加元素

mutable的方法是使用数组的`.unshift`函数在数组之前添加元素. Array.prototype.unshift mutate数组, 不是我们想要的结果.

这里是如何用immutable的方法在数组前添加一个元素的方法,适用于Redux:

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [1, 2, 3];
  */

  const newItem = 0;
  return [    // 新的数组
    newItem,  // 添加的第一个元素
    ...state  // 在最后展开数组
      ];
```

Redux:给一个数组添加项目

mutable的方法是使用数组的`.push`函数,在数组的末尾添加一个项目.但是这会mutate数组.

immutably的方法:

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [1, 2, 3];
  */

  const newItem = 0;
  return [    // a new array
    ...state, // explode the old state first
    newItem   // then add the new item at the end
  ];
```

也可以使用`.slice`方法拷贝数组,之后mutate拷贝:

```javascript
function reducer(state, action) {
  const newItem = 0;
  const newState = state.slice();

  newState.push(newItem);
  return newState;
```


## 使用`map`方法更新数组的项目

数组的`.map` 函数调用你提供的函数,传递的参数是数组的每个项目,返回一个新的数组,使用每个新项目的返回值作为新数组的项目.

换句话说,如果你的数组有N个项目,需要返回的数组也是N条,就要使用`.map`函数.可以在一次传递替换更新一个或者多个项目.

如果数组N条,结束时比N少,可以使用`.filter`. 参见[`Remove an item form an array`](https://daveceddia.com/react-redux-immutability-guide/#remove-an-item-from-an-array-with-filter).

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [1, 2, "X", 4];
  */

  return state.map((item, index) => {
    // Replace "X" with 3
    // alternatively: you could look for a specific index
    if(item === "X") {
      return 3;
    }

    // Leave every other item unchanged
    return item;
  });
}
```

## Redux:更新数组中的一个对象

这个和上面的工作原理相同, 唯一的区别是,你需要构建一个新的对象,并返回一个想要改变的对象.

数组的`.map` 函数通过对数组每个条目调用函数返回一个新的数组,用函数返回值作为新数组的元素.

换句话说,如果你的数组有N条项目, 新的数组也需要N条项目, 就用`.map`. 可以更新一条或者多条项目.

在这个实例中,我们有一个数组包含了用户email地址的数组. 其中一个人改变了email地址,所以我们需要更新它. 这里演示的是如何用`action`的用户ID和新的email执行更新,你也可以使用其他的途径来执行更新.

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [
      {
        id: 1,
        email: 'jen@reynholmindustries.com'
      },
      {
        id: 2,
        email: 'peter@initech.com'
      }
    ]

    Action contains the new info:

    action = {
      type: "UPDATE_EMAIL"
      payload: {
        userId: 2,  // Peter's ID
        newEmail: 'peter@construction.co'
      }
    }
  */

  return state.map((item, index) => {
    // Find the item with the matching id
    if(item.id === action.payload.userId) {
      // Return a new object
      return {
        ...item,  // copy the existing item
        email: action.payload.newEmail  // replace the email addr
      }
    }

    // Leave every other item unchanged
    return item;
  });
}


```

## Redux:在一个数组中间插入一个条目

数组的`.splice`函数会在数组中插入一个项目,但是它会mutate一个数组.

因为我们并不想mutate原始的数组, 所以可以先做一下拷贝(`.slice`),之后使用`.splice`插入项目

其他的方法比包括拷贝新元素之前的所有元素,接着插入新的,然后拷贝之后的元素. 但是这么做很容易出错.

提示:要做单元测试. 这里非常容易出错.

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [1, 2, 3, 5, 6];
  */

  const newItem = 4;

  // make a copy
  const newState = state.slice();

  // insert the new item at index 3
  newState.splice(3, 0, newItem)

  return newState;

  /*
  // You can also do it this way:

  return [                // make a new array
    ...state.slice(0, 3), // copy the first 3 items unchanged
    newItem,              // insert the new item
    ...state.slice(3)     // copy the rest, starting at index 3
  ];
  */
}
```

## 根据数组元素的index来更新数组

我们可以使用`.map`方法返回一个特定索引(index)的新值,保持其他的值不变.

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [1, 2, "X", 4];
  */

  return state.map((item, index) => {
    // Replace the item at index 2
    if(index === 2) {
      return 3;
    }

    // Leave every other item unchanged
    return item;
  });
}
```

## 使用`filter`从数组中删除项目

数组的`.filter`函数调用你提供的函数,逐个传递进每个项目,返回的新数组的元素是条目输入时,函数返回值为true的条目.如果函数返回值为false,就从数组中删除.

如果你的数组有N条, 你需要返回的条目等于或者少于N,就可以使用`.filter`函数

```javascript
function reducer(state, action) {
  /*
    State looks like:

    state = [1, 2, "X", 4];
  */

  return state.filter((item, index) => {
    // Remove item "X"
    // alternatively: you could look for a specific index
    if(item === "X") {
      return false;
    }

    // Every other item stays
    return true;
  });
}
```


查看Redux 文档[`Immutable Update Patterns`](https://redux.js.org/docs/recipes/reducers/ImmutableUpdatePatterns.html). 有更多的技巧.

## 用Immer 使更新更为简单

如果你看看上面的immutable state更新代码,想退缩.我不会责怪你.

深度嵌套对象的更新很难阅读, 很难书写,也很难得到正确的结构. 单元测试是命令式的,但是即使这样也不会让代码更容易阅读和编写.

谢天谢地, 有一个库能帮上忙, 使用由 Michael Weststrate编写的[`Immer`](https://github.com/mweststrate/immer),可以让你编写你知道并喜欢的`[].push`,`[].pop`还有`=`编写mutable代码-Immer会接受这些代码,生成完美的immutable代码,像魔法一样.

赞! 来看开具体的工作

首先安装Immer(3.9kb gzipped,)

```bash
Yarn add immer
```

之后,导入`produce`函数,只要这一个函数, 就完成一切工作了.简单,明了

```javascript
Import produce from 'immer';

```

顺便讲一句,叫做"produce"是因为它产出一个新的值, 名字某种意义上和`reduce`相反, 这里是对名字的讨论[`issue on Immer's Github`](https://github.com/mweststrate/immer/issues/24).

从现在起,你可以使用`produce`函数构建一个极佳的mutable练习场所,你所有的mutations都会被具有魔法的JS 代理对象(Proxies
)处理. 这里的前后对比实例使用了纯JS版本的reducer和Immer 版本,对比一下更新嵌套对象的过程.

```javascript
/*
  State looks like:

  state = {
    houses: {
      gryffindor: {
        points: 15
      },
      ravenclaw: {
        points: 18
      },
      hufflepuff: {
        points: 7
      },
      slytherin: {
        points: 5
      }
    }
  }
*/

function plainJsReducer(state, action) {
  // Add 3 points to Ravenclaw,
  // when the name is stored in a variable
  const key = "ravenclaw";
  return {
    ...state, // copy state
    houses: {
      ...state.houses, // copy houses
      [key]: {  // update one specific house (using Computed Property syntax)
        ...state.houses[key],  // copy that specific house's properties
        points: state.houses[key].points + 3   // update its `points` property
      }
    }
  }
}

function immerifiedReducer(state, action) {
  const key = "ravenclaw";

  // produce takes the existing state, and a function
  // It'll call the function with a "draft" version of the state
  return produce(state, draft => {
    // Modify the draft however you want
    draft.houses[key].points += 3;

    // The modified draft will be
    // returned automatically.
    // No need to return anything.
  });
}
```

### 在React State上使用Immer

Immer也可以针对setState形式的对象更新形式.

你可能已经知道了React的`setState`有函数式的形式,接收一个函数,并传递当前值, 函数返回新的值:

```javascript
onIncrementClick = () => {
  // The normal form:
  this.setState({
    count: this.state.count + 1
  });

  // The functional form:
  this.setState(state => {
    return {
      count: state.count + 1
    }
  });
}
```

Immer的`produce`函数可以被插入到state更新函数中.你会注意到,调用`produce`的调用方式只传递了单个参数-也就是更新函数-并不是两个参数`(state,draft=>{})`

```javascript
onIncrementClick = () => {
  // The Immer way:
  this.setState(produce(draft => {
    draft.count += 1
  });
}
```

这是因为Immer的`produce`函数设置返回的是一个柯里化函数,只有一个参数. 在这个例子中返回的函数已经准备接受state作为参数,使用draft调用你的更新函数

### 渐进采用Immer
Immer的一个很好的特性是,因为他很小,目标聚焦(仅仅返回新state的函数), 很容在已有代码中添加.

Immer向后兼容已经有的Redux  reducers,如果你在Immer的`produce`函数中包装已经存在的`switch/case`代码,所有的reducer测试仍然可以通过.

之前,我演示过, 传递给`produce`的更新函数可以隐式返回`undefined`,并且会自动挑选出针对`draft`state的变化.我没有提到的是,更新函数可以一个全新的对象,只要它没有对`draft`作出任何改变.

这意味着,已经编写好的返回全新state 的Redux reducer,也可以用Immer的`produce`函数包装,他们应该保持完全相同. 在这一点上,你可以轻松一块,一块地替换掉很难阅读的immutable 代码. 
看看官方实例[`从producers返回不同数据的各种方法`](https://github.com/mweststrate/immer#returning-data-from-producers)

## 完! 