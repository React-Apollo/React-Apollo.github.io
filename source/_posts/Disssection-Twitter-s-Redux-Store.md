---
title: Javascript Reducer函数实战
date: 2017-06-09 04:01:45
tags: [javacript,array] 
---
>javascript Reduce函数是比较强大的一个函数,在简书上看到有个作者写了这个函数的文章,也是看到有个问题就向他请教,大神很忙,但是仍然在github上做了答复,我对那个问题搞明白了,所以写了下面这个文章,但是没有写完,现在陪老娘在医院,又把这个问题翻出来看,又不懂了,还是拉锯战啊. javascript的编程中,我开始感到看别人的源码最难的地方实际还是两个,一个是数组方法的灵活应用,另一个是对象的浅拷贝和深拷贝的问题.这两个问题要是有深刻的体会,看源码的难度会降低很多.reduce,slice,splice,concat函数是明星.遇到这几个函数的时候就有些看不懂,所以掌握这几个函数是非常重要的. 深拷贝和浅拷贝的问题其实和javascript的对象和函数都是传引用赋值息息相关,一句话解决对象的共享还是独享的问题.javascript的设计模式很多都是利用对象很函数的传引用赋值的特点来完成的.所以这儿地方也是非常的重要.javascript的数组元素也可以是对象的引用.

本人是新手,最大的体会是学到的两个简单原则:1 对象是用来组织数据和相关方法的,所以组织方式越简单,越灵活越好,由于js的对象和函数都可以传引用赋值,所以在js中,以对象字面量和数组的组织方式真的是非常的强大,之所以这么讲,就是要把学习数组的方法提到新的高度.2 编程到底是在干什么？ 我逐渐体会到编程也就是解决信息的传递，存储和处理的问题. 所以很多问题其实稍微抽象一下,问题可能会简单一点. 我简单的写了一个东西,在学习React/Redux的时候,总是掌握不了实质,就是Redux中的state的实质是什么.前面学习的时候,总是言必称state,想了各种办法去了解什么是state，为什么要这样设计.其实再抽象一下,这不就是一个小型的数据库吗？可以这样说吗？当然可以了,我看了一本介绍React的书,有点确认了,当我这几天再读F8 app的代码官方文档的时候,facebook直接就是把Redux称为数据层.我还想了一些办法来理解Redux，比如说借用中介者模式,MVC解耦和模式,但是如果抽象为数据层,那么还有什么问题解决不了的吗？ 如果接触过任何一种web框架语言,例如php/mysql,node/mongodb.每种都是解耦和,每种都是中介者模式.所以在理解这些概念的时候最基础的内容可能是最解决问题的条件.你可以梳理一下这些框架中与数据库操作都有哪些? 连接数据库,数据库操作语句,数据库文件,返回值等等.这些东西在react/redux中都能找到一摸一样的内容.web框架里的数据库操作和redux的操作是完全一样的,有什么奇怪的吗？都是数据库.

Redux的文档中有个redo,undo的例子,我最近又重新看redux文档的时候，感觉这一部分讲的真是好,以前怎么没有理解呢？  有三个缺陷一个是对于state的数据结构的理解,一个是堆栈方法使用理解,另一个就是js的浅拷贝的问题。前面看那本数据结构的书,也不得法,但是硬着头皮把几种数据结构拿下以后,突然觉得好多问题都找到了解决办法,计算机中对于数据结构和算法的重视不是白来的.state如果作为一个简单数据库,他里面就是一些`键值对`. 由于js中对象可以传引用,所以可以很容易的建立一个类数据库的结构.其他语言可以吗？

#####下面我们就贯彻以上的理念,来研究一些基础的内容。
第一个就是Reducer函数,参考 [MDN](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Array) 文档

直接看代码例子

```
//accumulator是累加值,currentValue是当前遍历的值
[0,1,2,3,4].reduce( (accumulator, currentValue, currentIndex, array) => {
  return accumulator + currentValue;
}, 10);
```
___
| callback | accumulate |currentValue  |currentIndex  | array |return  |
|:-|:-|:-|:-|:-|:-|
|第一次调用 |10  |0  |0  | [0,1,2,3,4] | 10 |
|第二次调用 | 10 |1  | 1 | [0,1,2,3,4] | 11 |
|第三次调用 | 11 | 2 | 2 | [0,1,2,3,4] |13  |
|第四次调用 | 13 | 3 |3  | [0,1,2,3,4] | 16 |
|第五次调用 | 16 | 4 |4  | [0,1,2,3,4] |20  |

第一个遍历，accumulate等于10.遍历的数组元素是0，index是0.这是巧合。数组还是[0,1,2,3,4]。返回的值是初始值加当前的数组元素值，也就是返回accumulate+array[currentIndex]。return的就是 10+array[0]=10.

第二个遍历，accumulate就是10，遍历的数组元素是1，index是1.这也是巧合。数组还是[0,1,2,3,4]。返回的值是accumulate加当前的数组值，accumulate+array[currentIndex]。
也就是返回 10+array[1]=11.

第二个遍历和第一个遍历的区别就是初始值来源不同。第一个遍历的是reduce带进来的数据。第二个遍历使用的是第一个遍历返回的值。
后面的几个遍历就和第二个遍历一样了。



*数组扁平化*
```
var flattened = [[0, 1], [2, 3], [4, 5]].reduce(function(a, b) {
    return a.concat(b); //要了解concat的使用,返回的是
    //数组合并的返回对象
}, []); //起始是空数组
// flattened is [0, 1, 2, 3, 4, 5]
```
___

就这么简单,但是灵活变动起来也不是太好理解啊
看这个计算器的React-Native的代码,在UI组件中渲染出计算器的几个按键的方法

```
 var Types = { //类型
  NUMBER: 'NUMBER',
  DECIMAL: 'DECIMAL',
  SIGN: 'SIGN'
};

var inputs = [
  {value: 1, type: Types.NUMBER},
  {value: 2, type: Types.NUMBER},
  {value: 3, type: Types.NUMBER},
  {value: 4, type: Types.NUMBER},
  {value: 5, type: Types.NUMBER},
  {value: 6, type: Types.NUMBER},
  {value: 7, type: Types.NUMBER},
  {value: 8, type: Types.NUMBER},
  {value: 9, type: Types.NUMBER},
  {value: '+/-', type: Types.SIGN},
  {value: 0, type: Types.NUMBER},
  {value: '.', type: Types.DECIMAL},
];
//操作符的配置
var operations = [
  {value: '/', color: '#c77ccc', altColor: '#b16eb7', operation: OPERATION_DIVIDE},
  {value: '-', color: '#f8b055', altColor: '#dc9c4c', operation: OPERATION_SUBTRACT},
  {value: '+', color: '#f796d2', altColor: '#e088be', operation: OPERATION_ADD},
  {value: 'x', color: '#6fcdf4', altColor: '#65badd', operation: OPERATION_MULTIPLY}
];

renderInputRows() {
    var {inputNumber, inputSigned, inputDecimal} = this.props;//注意在redux中那个地方返回了这三个函数的名字
    return inputs.reduce((collection, input) => {//这里的reduce是怎么用的呢？
      if (collection[collection.length - 1].length === 3) {//为什么等于3
        collection.push([]);
      }
      collection[collection.length-1].push(input);
      return collection;
    }, [[]]).map((group, rowIndex) => {
      var columns = group.map((item, columnIndex) => {//看看map的方法
        return (
          <TouchableHighlight
            key={'inputRow_' + rowIndex + '_inputCol_' + columnIndex}
            underlayColor="#ededed"
            style={styles.input}
            onPress={() => { //dispatch方法
              if (item.type === Types.NUMBER) {
                inputNumber(item.value);
              } else if (item.type === Types.DECIMAL) {
                inputDecimal();
              } else if (item.type === Types.SIGN) {
                inputSigned();
              }
            }}>
            <Text style={styles.inputText}>{item.value}</Text>
          </TouchableHighlight>
        );
      });

```


看看这个数组的reducer方法的使用.[源代码在这里](https://github.com/benoitvallon/react-native-nw-react-calculator)

这个我稍后再补充,会补充大神给我的解答.

```
 var Types = {
  NUMBER: 'NUMBER',
  DECIMAL: 'DECIMAL',
  SIGN: 'SIGN'
}

var inputs = [
  {value: 1, type: Types.NUMBER},
  {value: 2, type: Types.NUMBER},
  {value: 3, type: Types.NUMBER},
  {value: 4, type: Types.NUMBER},
  {value: 5, type: Types.NUMBER},
  {value: 6, type: Types.NUMBER},
  {value: 7, type: Types.NUMBER},
  {value: 8, type: Types.NUMBER},
  {value: 9, type: Types.NUMBER},
  {value: '+/-', type: Types.SIGN},
  {value: 0, type: Types.NUMBER},
  {value: '.', type: Types.DECIMAL},
];
//这里其实是有一维数组转为二维数组，打印结构可以看到.
//注意reduce的起始值就是一个二维数组.
var result = inputs.reduce((collection, input) => {
      if (collection[collection.length - 1].length === 3) {
        collection.push([]);
      }
      collection[collection.length-1].push(input);
      return collection;
    }, [[]])

console.log(result)
console.table(result)
```


再看看下面这里两段代码
```
let str = `name,  age,  hair\nMerble,  35,  red\nBob,  64,  blonde`;
function lameCSV(str) {
  return str.split('\n').reduce(function(table, row){
    table.push(row.split(',').map(function(c) {return c.trim();}));
    return table
  }, [[]]);
};
lameCSV(str);

```
___

```
var arr=[0,1,2,3,4,5,6,7,8];
 var result = arr.reduce((collection, input) => {
      if (collection[collection.length - 1].length === 3) {
        collection.push([]);
      }
      collection[collection.length-1].push(input);
      console.log(collection);
      return collection;
    }, [[]]);
```
___
[感谢大神的帮助,大神的github](https://github.com/zaxlct/baike_spider/issues/1)
reduce这个方法还能演变出什么花样来呢？数组的操作真的是一个需要好好学习的内容.