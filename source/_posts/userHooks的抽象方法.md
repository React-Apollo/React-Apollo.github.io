---
title: useHooks的函数抽象
date: 2019-01-29 21:39
categories: 技术备忘
tags: [React,React-Hooks]
---


 # useHooks的函数抽象

## React Hooks的引入

>作为实例，表单的输入方法，和setState的方法都是完全一样的，所以可以可以使用`useState`进一步的做抽象

```jsx
const useFormInput=(intialValue)=>{
   const [value,setValue]=useState(intialValue);
   
   const handleChange=(e)=>{
      setValue(e.target.value);
   }
   
   return {
     vaule,
     onChange:handleChange
   };
}
```


`在函数式组件中使用时引入不同的初始值`

```jsx
const Component=()=>{
  const name=useFomrInput("Mary");
  const surname=useFormInput("Poppins");
  
  return (
  
   <section>
     <input {...name}/>
     <input {...surname}/>
   </section>
  )
}
```
