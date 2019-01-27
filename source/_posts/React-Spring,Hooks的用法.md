---
title: React-Spring,Hooks的用法
date: 2019-01-27 20:19
categories: 技术备忘
tags: [React,React-Hooks]
---

<script src="https://cdn.bootcss.com/mathjax/2.7.5/latest.js"></script>
{{TOC}}

# React-Spring，Hooks的用法

React-Hooks让组件的状态管理简洁了很多。下面是React-Spring的Hooks用法

```javascript
//Hooks.jsx
import React from 'react';
import { useSpring, animated } from 'react-spring';

const HookedComponent = () => {
    const [props] = useSpring({
        opacity: 1,
        color: 'white',
        from: { opacity: 0 },
        delay: '2000'
    })
    return <animated.div style={props}>This text Faded in Using hooks</animated.div>
}

export default HookedComponent;
```



