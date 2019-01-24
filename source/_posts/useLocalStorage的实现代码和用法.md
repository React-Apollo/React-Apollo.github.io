---
title: useLocalStorage的代码
date: 2019年1月24日 上午9:53
categories: 技术备忘
tags: [React,ReactHooks]
---

> `useLocalStorage`的Hooks,在使用`useState`时，先判断`localStorage`中是否有对应键的键值，如果有就取出，如果没有就设为空，等待后面传入值。


```javascript
import { useState, useEffect } from 'react';

// Usage
function App() {
  // Similar to useState but we pass in a key to value in local storage
  // With useState: const [name, setName] = useState('Bob');
  const [name, setName] = useLocalStorage('name', 'Bob');

  return (
    <div>
      <input
        type="text"
        placeholder="Enter your name"
        value={name}
        onChange={e => setName(e.target.value)}
      />
    </div>
  );
}

// Hook
function useLocalStorage(key, initialValue) {
  // The initialValue arg is only used if there is nothing in localStorage ...
  // ... otherwise we use the value in localStorage so state persist through a page refresh.
  // We pass a function to useState so localStorage lookup only happens once.
  // We wrap in try/catch in case localStorage is unavailable
  const [item, setInnerValue] = useState(() => {
    try {
      return window.localStorage.getItem(key)
        ? JSON.parse(window.localStorage.getItem(key))
        : initialValue;
    } catch (error) {
      // Return default value if JSON parsing fails
      return initialValue;
    }
  });

  // Return a wrapped version of useState's setter function that ...
  // ... persists the new value to localStorage.
  const setValue = value => {
    setInnerValue(value);
    window.localStorage.setItem(key, JSON.stringify(item));
  };

  // Alternatively we could update localStorage inside useEffect ...
  // ... but this would run every render and it really only needs ...
  // ... to happen when the returned setValue function is called.
  /*
  useEffect(() => {
    window.localStorage.setItem(key, JSON.stringify(item));
  });
  */

  return [item, setValue];
}
```



