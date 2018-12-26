title: 摘要| Functional Redux Reducers with Ramda
date: 2018-02-27 21:44:34
categories: 技术备忘
tags: [React, FP, Ramda, Redux]
---

> [`原文地址`](https://alligator.io/react/functional-redux-reducers-with-ramda/)

## Example Redux Reducer-----------------------

假设我们要在 React 组件中展示一组 短吻鳄(gators)的列表,数据从 GatorAPI获取, 具体的数据并不重要.  现在需要把 fetch 的数据添加到 redux 的 state 树中

这个 state 的结构是
- `①` 在 all 数组中包括 gatorIds,没有重复值(Ramda中如何实现唯一值?)
- `②` 在 lookup 添加新的 gator对象的 hash ById 索引,  索引值是 id(如何实现索引)
- `③` 在获取数据成功以后, 改变 loading flag的状态, 以便于在渲染时,去掉 spinning组件
>**`Redux reducer的模式`**
Redux  reducer 的模式其实是固定的:
`(prevState,action)=>nextState` 
根据传入的 action,对State 做出修改. 就这么简单, 修改是 Immutable的. 哪怕是一个数字加1, 也会形成新的 state, 这里很有必要使用 FB  的 Immutable.js. 如果是 prevState 和 nextState 之间有公共部分, 虽然是两个不同的对象,但是在底层Immutable.js 可以共享两个对象的共同部分.注意这并不是引用.

### 实例代码

```js
const reverseMerge = flip(merge);

export function fetchSuccess(state, { payload: { gators } }) {
   const gatorIds = map(prop("id"), gators);
   const gatorLookup = indexBy(prop("id"), gators);

   return evolve(
     {
       all: compose(uniq, concat(gatorIds)),
       byId: reverseMerge(gatorLookup),
       loading: always(false)
     },
     state
   );
 }
```

### 使用的 Ramda函数

`①`always: Ramda 中一切都是函数, 如果想使用 int或者字符串,也有通过函数返回 always就是为了这个出发点,  `val=()=>val`,

`②`compose 函数:  看家函数, Ramda数据流思考的方向, 数据从右传入,经过一系列操作. 实例代码中的 用法可以翻译为 `uniq(concat(gatorIds,all))`,把 prevState 的 all 属性取出,然后和远程获取的数据拼接, 使用 uniq 函数去重

`③`evolve: 接收两个参数, 一组转换函数, 一个对象, 函数对对象的属性递归的进行处理

`④` flip 函数:  翻转两个参数的位置, `merge(a,b)`, 在 merge()中, 如果存在两个属性名相同, b对象的属性值会覆盖 a 的属性值, 在 Redux中, 操作是`merge(state,payload.data)` 我们希望在出现同名属性的时候, payload 的属性会覆盖 state 的属性. 但是在`evolve`函数中, state是作为最后一个参数传递, 所以这里借助`flip`函数交换一下参数的位置. 

`⑤` indexBy 函数:  提取一个对象的键值作为索引

```
[{ id: 1, title: "one" }, { id: 2, title: "two" }]

{ 1: { id: 1, title: "one" }, 2: { id: 2, title: "two" } }
```

`⑥` map 函数  ,  `map(elem=>console.log(elm),elements)`

`⑦` merge 函数  

`⑧` prop 函数:  返回对象的属性值,   

```
     prop("a",{a:"alligator",b:"bayou",c:"cayman"})
     
     //=> "alligator" 
```

`⑨` uniq函数, 接收一个列表,返回一个新列表,  重复值被去除 


###   再看看代码    
```js
const reverseMerge = flip(merge);

export function fetchSuccess(state, { payload: { gators } }) {
   const gatorIds = map(prop("id"), gators);
   const gatorLookup = indexBy(prop("id"), gators);

   return evolve(
     {
       all: compose(uniq, concat(gatorIds)),
       byId: reverseMerge(gatorLookup),
       loading: always(false)
     },
     state
   );
 }
```

1. 定义函数 reverseMerge,交换 merge 函数的参数
2. map, gators列表, 应用 prop("id"),因此获取到 ids列表
3. indexBy函数返回的列表可以通过 id属性值作为索引来访问
4. evolve 函数, 接收三个函数和 state, 三个函数分别对 state 的不同属性做出修改
5. state 中的all列表传递给 compose 函数和从 API获取的 gatorIds 合并, 去重, 然后返回
6. state中的 byId 对象传递给 reverseMerge 函数,和 gatorLookup 合并, 重复值会被 gatorLookup 的属性值覆盖到
7. Loading的值被修改为 false. 

## 结论

实际使用时还有很多的函数可以使用, 在 Redux中有两个地方,ramda可以大有所为,一个就是这里, 还有一个地方就是container 组件包装时对state的筛选 , mapStateToProps,