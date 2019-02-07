---
title:React-Hooks Guide
date: 2019-02-05 10:40
categories: 技术备忘
tags: [React, Reack-Hooks]
---



## 内置方法
### useEffect

```jsx
function Demo() {
  const [count, setCount] = useState(0);

  // 在组件渲染之后的dom更新操作，可以代替 componentDidMount， 
  //componentDidUpdate方法
  useEffect(() => {
    // Update the document title using the browser API
    document.title = `You clicked ${count} times`;
  });

  return (
    <div>
      <p>You clicked {count} times</p>
      <button onClick={() => setCount(count + 1)}>Click me</button>
    </div>
  );
}
```

### useReducer

#### 原生 useReducer
>  接收的reducer类型 签名为：`(prevState,action)=>nextState`

```jsx
const initialState = { count: 0 };

function reducer(state, action) {
  switch (action.type) {
    case "reset":
      return initialState;
    case "increment":
      return { count: state.count + 1 };
    case "decrement":
      return { count: state.count - 1 };
  }
}

function Demo() {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({ type: "reset" })}>Reset</button>
      <button onClick={() => dispatch({ type: "increment" })}>+</button>
      <button onClick={() => dispatch({ type: "decrement" })}>-</button>
    </>
  );
}

```

#### useImmerReducer
> Redux的reducer对state进行操作时要保持immutable,新的Immer库使得Immutable操作简单化， `immer poducer`接受`prevState`,首先进行复制和冻结操作，然后返回修改后的对象。这一步先复制，在操作的过程在每一步的reducer中都会执行，所以这个过程抽象出来极大的简化了Immutable操作。

```jsx
import React from "react";
import { useImmerReducer } from "use-immer";

const initialState = { count: 0 };

function reducer(draft, action) {
  switch (action.type) {
    case "reset":
      return initialState;
    case "increment":
      return void draft.count++;
    case "decrement":
      return void draft.count--;
  }
}

function Counter() {
  const [state, dispatch] = useImmerReducer(reducer, initialState);
  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({ type: "reset" })}>Reset</button>
      <button onClick={() => dispatch({ type: "increment" })}>+</button>
      <button onClick={() => dispatch({ type: "decrement" })}>-</button>
    </>
  );
}
```


### useRef
> useRef 返回mutable对象的引用，指向react 虚拟dom元素， 可以传入初始值
```jsx
function Demo() {
  const inputEl = useRef(null); 
  const onButtonClick = () => {
    // `current` points to the mounted text input element
    inputEl.current.focus();
    
  };
  return (
    <>
      <input ref={inputEl} type="text" />
      <button onClick={onButtonClick}>Focus the input</button>
    </>
  );
}
```
## 外置方法

###  useContextReducer

>可以看做内置useReducer的全局state管理扩展


```jsx

switch (action.type) {
    case "INCREMENT":
      return state + 1;
    default:
      return state;
  }
}

function useCounter() {
  const [count, dispatch] = useContextReducer("counter", reducer, 0);
  const increment = () => dispatch({ type: "INCREMENT" });
  return { count, increment };
}

function IncrementButton() {
  const { increment } = useCounter();
  return <button onClick={increment}>Increment</button>;
}

function Count() {
  const { count } = useCounter();
  return <div>{count}</div>;
}
//两个子组件都从顶层组件获取函数或者state,这里用sate似乎不太严谨
// Redux中分的很清楚，react-redux作为一个组件来组织应用的state,
//这个state是react-redux组件内部的， 要传递给container,就用了mapStateToProps来进行转换。
function Demo() {
  return (
    <Provider>
      <Count />
      <IncrementButton />
    </Provider>
  );
}
```


### useContextState

```jsx
function useCounter() {
  const [count, setCount] = useContextState("counter", 0);
  const increment = () => setCount(count + 1);
  return { count, increment };
}

function IncrementButton() {
  const { increment } = useCounter();
  return <button onClick={increment}>Increment</button>;
}

function Count() {
  const { count } = useCounter();
  return <div>{count}</div>;
}

function Demo() {
  return (
    <Provider>
      <Count />
      <IncrementButton />
    </Provider>
  );
}

```


## 其他的抽象包装方法

### useAsync
> 异步操作的包装方法
```jsx
const fn = () =>
  new Promise(resolve => {
    setTimeout(() => {
      resolve("RESOLVED");
    }, 1000);
  });

function Demo() {
  const { loading, value, error } = useAsync(fn);

  return (
    <div>{loading ? <div>Loading...</div> : <div>Value: {value}</div>}</div>
  );
}
```

### use-hooks/ axios

> 对 axios 的包装

```jsx
import React, { useState } from 'react';

import useAxios from '@use-hooks/axios';

export default function App() {
  const [gender, setGender] = useState('');
  const {
    response,
    loading,
    error,
    query,
  } = useAxios({
    url: `https://randomuser.me/api/${gender === 'unknow' ? 'unknow' : ''}`,
    method: 'GET',
    options: {
      params: { gender },
    },
    trigger: gender,
    filter: () => !!gender,
  });

  const { data } = response || {};

  const options = [
    { gender: 'female', title: 'Female' },
    { gender: 'male', title: 'Male' },
    { gender: 'unknow', title: 'Unknow' },
  ];

  if (loading) return 'loading...';
  return (
    <div>
      <h2>DEMO of <span style={{ color: '#F44336' }}>@use-hooks/axios</span></h2>
      {options.map(item => (
        <div key={item.gender}>
          <input
            type="radio"
            id={item.gender}
            value={item.gender}
            checked={gender === item.gender}
            onChange={e => setGender(e.target.value)}
          />
          {item.title}
        </div>
      ))}
      <button type="button" onClick={query}>Refresh</button>
      <div>
        {error ? error.message || 'error' : (
          <textarea cols="100" rows="30" defaultValue={JSON.stringify(data || {}, '', 2)} />
        )}
      </div>
    </div>
  );
}
```

### useToggle

```jsx
function Demo() {
  const [currentValue, toggleAway] = useToggle(true);
  return <div onClick={toggleAway}>{currentValue ? "🍎" : "🍏"}</div>;
}
```



