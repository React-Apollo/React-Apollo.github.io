---
title: 翻译|Redux Selectors: A Quick Tutorial 
date: 2019-04-23 09:28
categories: 技术备忘
tags: [React,Redux,Selectors]
---

[原文在此:Redux Selectors: A Quick Tutorial](https://daveceddia.com/redux-selectors/)

>你可能会在Redux中碰到"selector"这个概念.在这个教程中,我会解释一下selectors是什么,用途以及使用selectors的时机选择

## 什么是Selector?
`selector`是我们编写的一个小函数,接受整个`Redux`的`state`,并从中返回挑选出的值.

你知道`mapStateToProps`是如何工作的吗?了解它是如何接受整个state,筛选出值得吗?如果你了解话, Selector基本上做着同样的工作,附带的好处是,selector还同时通过缓存不变的state提升了性能.的确如此,Selector可以改善性能.我们后边会讨论整个问题.

如果你还不了解`mapStateToProps`的工作原理, 现在可能理解不了selector. 我建议你马上停下来, 去看看我的[Complete Redux Tuorial for Beginners](https://daveceddia.com/redux-tutorial/). Selectors属于高级概念,是在常规Redux之上的附加抽象层. 理解Redux的基础概念是明白selector工作的必须条件.
## State层级的结构的一个实例

Redux为我们提供了一个`store`,你可以放置**state**,在稍大型的app中,state通常是一个对象,这个对象的每个键都管理着一个独立的reducer.[^译注:如果你现在还不知道reducer是什么,就不要再往下看了, 需要学习Redux的基础知识]
假设我们的state对象结构如下:

```javascript
{
  currentUser: {
    token,
    userId,
    username
  },
  shoppingCart: {
    itemIds,
    loading,
    error
  },
  products: {
    itemsById,
    loading,
    error
  }
}
```

在这个虚构的实例中,保存了登录用户的信息,shop中的货物,以及用户购物车中的商品.
这里的数据是经过范式化(normalized)的,所以购物车中的商品看到的只是指向实体货物的ID.当一个用户在购物车中添加一件商品,商品本身并没有被复制的购物车中-只有商品的ID添加到 `shoppongCart.itemIds`数组中.[^译注:范式化是数据库的概念,避免冗余和嵌套的结构,实体都通过ID应用]

## 首先看看没有使用selector的情况
在需要从Redux的state提取数据并注入到React组件的时候, 我们需要编写一个`mapStateToProps`函数,用于接受整个state,并选择出组件需要的部分.

假设你需要展示用户购物车中的商品列表.因此需要items,但但是,`shoppingCart`中并没有items这一项.只有items们的IDs. 你需要用每个ID在`products.items`数组中查找出对应的商品信息. 下面是具体的执行方法:

```javascript
function mapStateToProps(state) {
  return {
    items: state.shoppingCart.itemIds.map(id => 
      state.products.itemsById[id]
    )
  }
}
```


## 修改了State的结构,mapStateToProps就没办法正常工作了

现在假设你(或者是开发组中的其他人)突发奇想, `shoppingCart`应该是`currentUser`的一个属性而不是独立的属性.那么现在的State结构变成下面的样子:

```javascript
{
  currentUser: {
    token,
    userId,
    username,
    shoppingCart: {
      itemIds,
      loading,
      error
    },
  },
  products: {
    itemsById,
    loading,
    error
  }
}

```

看看你干的好事,之前定义好的`mapStateToProps`函数就毁了. 原来指向`state.shoppingCart`,现在指向了`state.currentUser.shoppingCart`.

如果在代码中有一大堆的代码都引用了`state.shoppongCart`,那可有的改了.在你意识到完全有必要对state重新组织的时候,这个更新过程会阻碍你完成任务. 

如果我们只有唯一的途径把所有的state集中管理, 还有一些函数,调用时可以找到我们需要的数据...

是的,这正是selector所做的工作:)

## 重构:编写一个简单的selector

来重新编写一下被破坏掉的`mapStateToProps`, 把state的筛选放在selector中完成.

```javascript
// 这个函数放在全局作用于内
// 例如命名为 selectors.js,
// 在需要访问这一部分state的时候导入这个函数就可以了

function selectShoppingCartItems(state) {
  return state.currentUser.shoppingCart.itemIds.map(id => 
    state.products.itemsById[id]
  );
}

function mapStateToProps(state) {
  return {
    items: selectShoppingCartItems(state)
  }
}
```


下一次,如果state的组织结构发生变化, 你只需要更新一个selector函数就完成了所有的工作.超级简单.

说道命名,selector函数的的常见前缀是`select`或者`get`.当然遵循你app中其他的传统定义也完全可以.

##  不是每个地方都需要Selector

你可能注意到了,这里有点小题大做. 又多了一个要测试和编写的函数.如果需要添加一个新的state分支[^译注:这里按照reducer的用法,添加的新部分称为一个分支].所以又潜在的增加了要考虑的文件.

因此,对于简单的state访问,或者是一些你已经知道不大可能在很多地方被访问的state,就完全不需要selector.我个人遵循"要么全部使用,要么就完全不用的原则",编写要有意义,否则就直接跳过不用. 这个一个可选的抽象部分.

## 使用reselect获取更好的性能

之前编写的selecotor仅仅是单纯的函数. 这些selector隐藏了state结构的细节问题- 很棒!-但是对于性能完全没有帮助. 因为他们没有魔法caching(缓存).

名字有点让人想不明白,太(让人困惑),reselector被称为"selector"因为他从state中选择了数据,但是大多数情况下,程序员谈论"selectors"时,他们的真实意图是`缓存(*memoized*)`.

一个**‌缓存**函数会记住最后一次接收的参数. 之后,下一次被调用时, 它会首先检查新参数是不是和前一次的参数相同.如果相同,就返回旧的值(不需要重新计算了),反之就会进行新的计算,并且在再次记住新的一套参数和返回值. Memoization(备忘,不是memorization(记忆),即使概念相同),是缓存的基本意义. 
为了创建备忘 selector,你可以编写自己的memoization函数,或者可以安装`reselect`库(还有其他的库,但是selector是最流行的)

```javascript
yarn add reselect
```

之后就可以使用`reselect`库提供的`createSelector`函数创建备忘selector. 我们要把之前的selector分解成一组更小的原子selector[^译注:原子性基本如果是函数就可以理解为单一职责,不肯再分的功能].稍后解释.

```javascript
import { createSelector } from 'reselect';

const getProducts = state => state.products.itemsById;
const getCartItemIds = state => state.currentUser.shoppingCart.itemIds;

export const selectShoppingCartItems = createSelector(
  getProducts,
  getCartItemIds,
  (products, itemIds) => itemIds.map(id => products[id])
);

```

这里是什么情况?

我们已经把函数分割成了小的片段. 每个片段就是针对每一块数据的单独selector. `getProducts`知道在哪里查找products,`getCartItemIds`知道怎么找到购物车中的东西.

之后,用`createSelector`把小的片段组合起来.这个函数接受片段(所有你定义的)一个变换函数(transform function),就是最后一个调用的参数.

变换函数从片段接受结果,然后可以在需要的时候执行,无论什么时候,它都会通过总selector返回("master" selector).

`createSelector`返回的总selector时,接收的是`state`和可选的`props`,传递`(state,props)`至每一个片段selector.

所有这些工作给了你一个很大的收益: *transform function*, 这个函数可能计算很耗时间,花销也很大,它只有在片段之一返回不同于之前的值是才会执行(要确保片段足够快,要执行例如单纯的属性访问,不要做数组的遍历访问).

我重申一下,如果的变换函数代价不大(仅仅只执行属性访问,类似`sate.foo.bar`,或者添加一对数字),完全没有必要创建备忘函数.

## 只备忘一次,还是所有的?
`reselect`库只能记住最近一次的调用结果.如果你想让他记住多组的参数和返回值,看看`re-reselect`库,这个库包装了`reselect`,所以外在是一样的,但是在内部,可以缓存更多的东西.

## 以上就是 Selector的核心

包括了基础的内容!希望你现在对selector有点印象了.


