---
title: Transducer 关键代码的解析
date: 2018-01-31 19:05:07
categories: 技术备忘
tags: [hoc,transducer]
---


## 代码块 ##

```js
const mapping = (f) => (reducing) => (result, input) => reducing(result, f(input));

const filtering = (predicate ) => (reducing) => (result, input) => predicate(input) ? reducing(result, input) : result;


//2 
  mapping((x) => x + 1)(filtering((x) => x % 2 === 0)((xs, x) => {
  xs.push(x);
  return xs;
}));


mapping(fn)(reducing)   ====>     reducuing(result, fn(input))

在flitering 中  ，  fn(input)就作为filtering的 input了      predicate(fn(input))

const xform = R.compose(
  mapping((x) => x + 1),
  filtering((x) => x % 2 === 0),
  mapping((x=>x*x))
  
  );

```
### 解释

#### mapping,filter 函数
上例中的mapping 函数和 filter 函数都是 Reducer函数
1. mapping 函数的传入 `fn` 作为处理遍历数组值的函数,`result`是作为accum 变量, `input`作为数组的初始值. `reducing`就是 reducer 函数.上面的代码可以改写为:
```
mapping(fn)(reducing)  ==可以变化为reducer的标准模式==>     reducuing(result, fn(input))
```
传入的 fn先对输入的数组元素做一下应用.然后再执行 reduce的操作.  实际如果 reducing 函数之前 compose 了很多的函数,那个都会传入到
compose时，filtering就作为 mapping 的reducing传入。和上面的方式是一样的 。这里有点绕， 还是高阶函数的问题。   
compose函数时，  方向从左向右，  但是 transducing中compose的最后一个函数是作为fn传递给后面的reducing函数的。
这个地方就是理解transducer的难点。  compose的方向和reducing中的方向是不同的。




