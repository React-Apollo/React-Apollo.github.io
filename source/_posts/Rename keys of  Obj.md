---
title: Rename key of Object 
date: 2018-01-26 7:25:28
categories: Ramda-cookbook
tags: [Ramda,fp,javascript]
---
> 函数签名：`{a:b}->{a:*}->{b:*}`
> 关键点是`{oldkey: newkey}`

### 步骤是：
1. `R.key(obj)` 取出对象的键作为数组
2. 使用`R.assoc`把要转换键名的对象复制空对象中
3. 使用`R.reduce`函数遍历函数，改变键名
### 难点：
1. R.assoc可以改变或者添加新属性，第一个参数为要改变或者添加的属性，第二个参数为属性值，第三个为对象
```
R.assoc('c', 3, {a: 1, b: 2}); //=> {a: 1, b: 2, c: 3}
```
2.  reduce的使用，reduce是Ramda中应用最广泛的函数

```
R.reduce((acc, key) => R.assoc(keysMap[key] || key, obj[key], acc), {}, R.keys(obj))
```

`R.keys`取出对象的键名(属性名)最为遍历的数组，原始对象并没有通过参数传递，通过键名几可以访问属性值

`R.reduce`函数中的三个位置，一是`R.assoc函数`,用于转换的函数，`{}`为初始值，`R.key(obj)`为原始对象的键名组成的数组

刚开始第一步，对象为空， `R.assoc`第一个参数为keysMap[key]，keyMap的定义为`{oldkey:newkey}`，所以`keysMap[key]`取出的就是新的键名，`obj[key]`就是原对象中的属性值， 复制到空对象中。第一步可以分解为：
```
 R.assoc(newKey, value, {}) 
```
这样就把第一个对象属性名改变，并存入到新的空对象中
接下来的方式就是Reduce的标准模式了。

####  这个方法有点绕，绕着绕着就明白了。 

<script src="https://embed.cacher.io/825631865d31aa44acaa1191582c12f27e5ea114.js?a=34c25bf41a39c6352202f03679d458ad&t=github_gist"></script>
