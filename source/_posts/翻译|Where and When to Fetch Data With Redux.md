---
title: 翻译|Where and When to Fetch Data With Redux
date: 2019-04-28 12:07
categories: 技术备忘
tags: [React,Redux]
---
[原文:`Where and When to Fetch Data With Redux`](https://daveceddia.com/where-fetch-data-redux/)

>如果固件为了渲染需要一些数据,你想使用Redux获取数据,并保存在Redux  Store中,那么什么时间点是调用API的最好时机?
- 在`componentdidMount`生命周期函数中启动Action

##  在Redux中调用API

假设你要显示一个产品列表. 后台API是:'GET/products',可以这么创建Redux action


`productAction.js`
```javascript
export function fetchProducts() {
  return dispatch => {
    dispatch(fetchProductsBegin());
    return fetch("/products")
      .then(handleErrors)
      .then(res => res.json())
      .then(json => {
        dispatch(fetchProductsSuccess(json.products));
        return json.products;
      })
      .catch(error => dispatch(fetchProductsFailure(error)));
  };
}

// Handle HTTP errors since fetch won't.
function handleErrors(response) {
  if (!response.ok) {
    throw Error(response.statusText);
  }
  return response;
}
```

注释:`fetch()`不会抛出HTTP error,例如404错误. 这一点让人有点困惑,如果你之前使用的是其他的方法,例如[`axios`](https://github.com/axios/axios). [`看这里`](https://www.tjvantoll.com/2015/09/13/fetch-and-errors/),有关于fetch和错误处理的内容.

在Redux中,使用redux-thunk获取数据
通常,actions必须是一个简单对象.返回一个函数,例如实例中的`fetchProducts`,超出了范围,Redux不允许这么做.至少在没有协助的情况下不行.
所以`redux-thunk`就出现了.`redux-thunk`是一个中间件可以告诉Redux如何处理新类型的action(如果很好奇,可以看看[`thunk到底是什么东东?`](https://daveceddia.com/what-is-a-thunk/))

> 等等.神马情况?
> redux-thunk,Reducers有些意义. redux-thunk是完全捏造出来的吧?

如果你处在对Redux似懂非懂的边缘,要大胆大往前尝试,尽管可能不太明白到底是怎么一回事.我会把这件事说明白.

即使你已经搞清楚了,或许理解的很透彻. 回顾一下也是值得的.

使用`npm install redux-thunk`安装redux-thunk.接着需要添加几行代码扩展Redux store,以便使用新的中间件

```javascript
import { createStore, applyMiddleware } from "redux";
import thunk from "redux-thunk";

const store = createStore(
  rootReducer,
  applyMiddleware(thunk)
);
```

重要的一件事要注意,在传递给Redux之前,必须要用`applyMiddleware`包装中间件. 这里还出现了`rootReducer`,之后我们会看看它的出处.

这段代码可以卸载`index.js`中,或者写在自己的文件中(`store.js`是个很好的名字).Redux不关心文件放在那里.如果你愿意,放在一起也可以.只要能够获取到store,并通过`Provider`提供给app就设置完成了.


## 如何命名 Redux Actions

Redux action获取数据通常是三部曲:BEGIN,SUCCESS,FAULURE,这不是必须的,只是约定俗成.

在起始API调用之前,dispatch BEGIN action
api调用成功之后, dispatch SUCCESS和数据.如果api调用失败,dispatch FAILURE和error.

有时候, 最后一次的调用用ERROR代替.不太理想,只是为了统一.

BEGIN/SUCCESS/FAILURE 模式很好,因为他给出了一个挂钩用于追踪具体发生的事-例如,设置 "loading"标志为`true`标识BEGIN action, SUCCESS或者FAILURE时设定为`false`.下面是action的样子:

`productActions.js`
```javascript
export const FETCH_PRODUCTS_BEGIN   = 'FETCH_PRODUCTS_BEGIN';
export const FETCH_PRODUCTS_SUCCESS = 'FETCH_PRODUCTS_SUCCESS';
export const FETCH_PRODUCTS_FAILURE = 'FETCH_PRODUCTS_FAILURE';

export const fetchProductsBegin = () => ({
  type: FETCH_PRODUCTS_BEGIN
});

export const fetchProductsSuccess = products => ({
  type: FETCH_PRODUCTS_SUCCESS,
  payload: { products }
});

export const fetchProductsFailure = error => ({
  type: FETCH_PRODUCTS_FAILURE,
  payload: { error }
});
```

之后,在收到`FETCH_PRODUCTS_SUCCESS` action时用reducer保存products至Redux store. 也同样在获取数据开始时,设置`loading`标志为`true`,完成或失败时设置为`false`.

`productReducer.js`
```javascript
import {
  FETCH_PRODUCTS_BEGIN,
  FETCH_PRODUCTS_SUCCESS,
  FETCH_PRODUCTS_FAILURE
} from './productActions';

const initialState = {
  items: [],
  loading: false,
  error: null
};

export default function productReducer(state = initialState, action) {
  switch(action.type) {
    case FETCH_PRODUCTS_BEGIN:
      // Mark the state as "loading" so we can show a spinner or something
      // Also, reset any errors. We're starting fresh.
      return {
        ...state,
        loading: true,
        error: null
      };

    case FETCH_PRODUCTS_SUCCESS:
      // All done: set loading "false".
      // Also, replace the items with the ones from the server
      return {
        ...state,
        loading: false,
        items: action.payload.products
      };

    case FETCH_PRODUCTS_FAILURE:
      // The request failed. It's done. So set loading to "false".
      // Save the error, so we can display it somewhere.
      // Since it failed, we don't have items to display anymore, so set `items` empty.
      //
      // This is all up to you and your app though:
      // maybe you want to keep the items around!
      // Do whatever seems right for your use case.
      return {
        ...state,
        loading: false,
        error: action.payload.error,
        items: []
      };

    default:
      // ALWAYS have a default case in a reducer
      return state;
  }
}
```

最后只需要把products传递给`ProductList`组件,这个组件最终显示列表,同时也负责启动数据获取工作.

`ProductList.js`
```javascript
import React from "react";
import { connect } from "react-redux";
import { fetchProducts } from "/productActions";

class ProductList extends React.Component {
  componentDidMount() {
    this.props.dispatch(fetchProducts());
  }

  render() {
    const { error, loading, products } = this.props;

    if (error) {
      return <div>Error! {error.message}</div>;
    }

    if (loading) {
      return <div>Loading...</div>;
    }

    return (
      <ul>
        {products.map(product =>
          <li key={product.id}>{product.name}</li>
        )}
      </ul>
    );
  }
}

const mapStateToProps = state => ({
  products: state.products.items,
  loading: state.products.loading,
  error: state.products.error
});

export default connect(mapStateToProps)(ProductList);
```

这里引用数据用了`state.products.<somedata>`,没有用`state.<somedata>`, 因为我假设你可有有不止一个reducer,每个reducer处理自己的一块state. 为了让多个reducer一同工作,我们需要`rootReducer.js`文件, 它会把所有的小块reducer组合在一起:

`rootReducer.js`
```javascript
import { combineReducers } from "redux";
import products from "./productReducer";

export default combineReducers({
  products
});
```

截止,在创建store时, 可以传递这个"root" reducer:

`index.js`
```javascript
import rootReducer from './rootReducer';

// ...

const store = createStore(rootReducer);
```

## Redux中的错误处理
这里的错误处理内容很少,但是基础的结构和执行api调用的action是一样的. 总体的思路是:

1. 在调用失败时dispatch FAILURE
2. 在reducer中通过设置标识或保存出错信息来处理 FAILURE action.
3. 向组件传递错误标识或者信息,根据需要条件性渲染错误信息

## 但是它将会渲染两次
这是一个常见的担忧.的确是会渲染超过不止一次.
在state为空的时候渲染一次, 根据loading state会重新渲染,在显示数据时还要渲染. 恐怖! 三次渲染!(如果直接跳过loading 会减微微两次).

你之所以担心不必要的渲染是因为性能的考虑,但是不要担心,单个渲染速度很快. 如果明显很慢,那就需要找到导致变慢的原因.

这样考虑:app需要在没有内容时显示一些东西,可以是加载提示,或者错误提示. 你也不愿意在在数据到来之前显示空白页面.这些提示为了我们增强用户体验的机会.

## 但是组件不应该自己去获取数据
从构架的观点看,如果一个父"东东"(组件,函数,或路由)在他加载组件之前自动获取数据就更好了. 组件自己觉察不到无意义的调用. 他们可以幸福的等待数据.

有一些方法可以修复这个问题,但是凡事都有得有失. 魔术加载是魔术,它们需要更多的代码.

## 解决数据获取的不同方法

有很多方式可以重构这段代码.没有最好的方法,因为每个方法都有适用范围, 因为对一个实例是最好的对于其他的实例未必如此.

在`componentDidMount`中获取数据不是最好的一个,但是是最简单的完成工作的方法.

如果你不喜欢这么作,还要其他一些方法可以尝试:
-  把API调用从Redux Action中转移到`api`模块中, 在action中调用(分离关注点).
-  组件直接调用API模块,然后在数据返回时从内部组件dispatch action. 类似 [`Dan Abramov的演示`](https://egghead.io/lessons/javascript-redux-dispatching-actions-with-the-fetched-data)
-  使用类似[`redux-dataloader`](https://github.com/kouhin/redux-dataloader)或者[`redu-async-loader`](https://github.com/recruit-tech/redux-async-loader).或者[`Mark Eriksons的数据获取库方法之一`](https://github.com/markerikson/redux-ecosystem-links/blob/master/component-data-fetching-preloading.md).
-  使用一个包装组件用于执行fetch操作- 在上面的例子中可以称为`ProductListPage`.之后"Page"关注fetching,"List"仅仅接受数据并渲染他们
-  使用`recompose`库把`componentDidMount`周期函数放入到高阶包装函数内-这个库是可以工作,但是可能作者要停止了[^译注,这个库的作者就是React的核心成员,recompose算是react hooks的前身]
-  很快你就可以使用React内置的suspense特性来获取数据了.

 
 
 ## 代码
 
 [`CodeSandbox`完整代码](https://codesandbox.io/s/j3378m4v3y)
 
 [可用的`api`](https://www.reddit.com/r/reactjs.json)


## 完成!

