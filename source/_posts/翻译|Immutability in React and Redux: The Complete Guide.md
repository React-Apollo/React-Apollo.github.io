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

现在来看看mutaility是如何工作的. 从整个`person`对象开始:

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

## Part one
## Part two
## Conclusion
