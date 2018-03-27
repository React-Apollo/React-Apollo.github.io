---
title: JavaScript的 this 关键字
date: 2017-01-10 15:04:34
categories: 技术备忘
tags: [javascript]
---



主要参考《javascrpt设计模式与开发指南》

javascript(缩写js)语言中的this和java,php中的this是完全不同的概念。
js中的this是动态的，总是指向一个对象，但是这个对象是谁，需要根据函数的调用上下文来决定。

1.    作为对象的方法调用(显示绑定)
2.    作为普通的函数来调用(默认绑定)
3.    作为构造器来调用
4.    call和apply方法调用


## 1作为对象的方法调用

```
var obj = {
		a: 1,
		getA: function(){
			alert ( this === obj ); // 输出：true
			alert ( this.a ); // 输出: 1
		}
	};

	obj.getA();  //函数被绑定在对象obj上，this指向obj对象
	//这种方法，可以立即看到绑定的对象是那一个，所以是最简单的

```
## 2作为普通函数的调用

```
//在浏览器的JavaScript 里，这个全局对象是window 对象。
	window.name = 'globalName';

	var getName = function(){ //这个函数没有指定对象，默认绑定在window对象上
		return this.name;
	};
	console.log( getName() ); // 输出：globalName

	//或者：
	window.name = 'globalName';

	var myObject = {
		name: 'sven',
		getName: function(){
			return this.name;
		}
	};
  //下面这个引用是比较迷惑人的，在用变量引用一个对象的方法时候，变量仅仅指向函数本身，和原来函数定义在哪个对象里没有任何关系，这一点要注意
	var getName = myObject.getName; //getName函数任然是默认绑定在window全局对象上
	console.log( getName() ); // globalName
```

`下面这个实例，我个人认为是js this中最为迷惑的地方，需要注意，可能学了很长时间都对这个地方迷惑，没有什么原因，js就是这么规定的。`

`那，到底规定什么了？就是 函数内部的函数，也就是闭包函数的对象是默认绑定在全局，全局，全局 对象上的，一定，一定，一定 要记住这一点`


```
<body>
		<div id="div1">我是一个div</div>
	</body>
	<script>

	window.id = 'window';

	document.getElementById( 'div1' ).onclick = function(){
		alert ( this.id ); // 输出：'div1'
		var callback = function(){  //这个函数内部的函数，他是默认绑定在window上的
			alert ( this.id ); // 输出：'window' 
		}
		callback();
	};

  //那么要是内部函数要使用外部函数绑定的对象怎么办。
  //好办，就是把外部函数的对象保存在一个变量中
  //经常在代码中看到的 var that=this就是这个作用
  //在内部函数要使用同一个对象就可以用that了。或者用 var  self=this 
  //这仅仅是变量的名字不同，道理都一样
	document.getElementById( 'div1' ).onclick = function(){
		var that = this; // 保存div 的引用
		var callback = function(){
			alert ( that.id ); // 输出：'div1'  //that指向了外部函数的对象
		}
		callback();
	};
```

在 ECMA es5的严格模式下
问题又有改变了。

```
use strict 

这时候，内部函数的this不在默认指向window对象，而是指向undefine，实际就是没有默认绑定对象。
```

## 3构造器调用 
 
```
var MyClass = function(){
		this.name = 'sven';
	};
	var obj = new MyClass();  //当使用构造器调用的时候，构造器返回一个对象，this就指向这个对象
	alert ( obj.name ); // 输出：sven

	var MyClass = function(){
		this.name = 'sven';
		return { // 显式地返回一个对象
			name: 'anne'
		}
	};
```

## 4call apply 调用
硬式绑定，通过传参方式动态改变函数的绑定对象。


```
  var obj1 = {
		name: 'sven',
		getName: function(){
			return this.name;
		}
	};

	var obj2 = {
		name: 'anne'
	};
	
	console.log( obj1.getName() ); // 输出: sven
	//下面这个函数硬式绑定到obj2对象上
	console.log( obj1.getName.call( obj2 ) ); // 输出：anne
	

```

这就是this的概念




	
		
	
	
	
	
	