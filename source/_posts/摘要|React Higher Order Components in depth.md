---
title: 摘要|React Higher Order Components in depth
date: 2018-02-13 23:32:45
categories: 技术备忘
tags: [React,fp,hoc]
---

{{TOC}}
>原文在[React Higher Order Components in depth](https://medium.com/@franleplant/react-higher-order-components-in-depth-cf9032ee6c3e)


已经有了中文版的翻译,  只做摘要

### 什么是高阶组件 HOC?

>HOC是包装另一个组件的 React 组件

通常是一个函数,作为类工厂, 
```js
hocFactory:: W: React.Component => E: React.Component
```

"wrap"部分:
1. Props 代理:  HOC负责操作传递给包装组件W 的 props.
2. HOC 扩展了 W的功能

###  HOC可以做什么

- 代码重用,逻辑抽象和 bootstrap 式的抽象(一般->特殊的样式定义)
- 渲染劫持 
- State抽象和操作
- Props 操作

### HOC 工厂的实现
讨论一下 props 代理和继承反转(Inheritance Inversion)

#### Props Proxy
```js
function ppHOC(WrappedComponent) {
  return class PP extends React.Component {
    render() {
      return <WrappedComponent {...this.props}/>
    }
  }
}
```

#### 通过 Props 代理可以做的事情

- 操控 props
- 通过 Refs 访问实例
- 抽象 State
- 用其他的元素包装组件

##### 操控 props
可以在 props 传递给包装组件之前,对 props 做出 read,add, edit和 remove 操作,
例如添加 props

```js
function ppHOC(WrappedComponent) {
  return class PP extends React.Component {
    render() {
      const newProps = {
        user: currentLoggedInUser
      }
      return <WrappedComponent {...this.props} {...newProps}/>
    }
  }
}
```

##### 通过 Refs 访问实例
可以通过 this 关键字访问包装的组件

例如 

```js
function refsHOC(WrappedComponent) {
  return class RefsHOC extends React.Component {
    proc(wrappedComponentInstance) {
      wrappedComponentInstance.method()
    }
    
    render() {
      const props = Object.assign({}, this.props, {ref: this.proc.bind(this)})
      return <WrappedComponent {...props}/>
    }
  }
}
```

##### state 抽象

可以通过给包装组件提供 props 和 回调函数来抽象出 state
实例是 smart component 处理 dumb component

```js
function ppHOC(WrappedComponent) {
  return class PP extends React.Component {
    constructor(props) {
      super(props)
      this.state = {
        name: ''
      }
      
      this.onNameChange = this.onNameChange.bind(this)
    }
    onNameChange(event) {
      this.setState({
        name: event.target.value
      })
    }
    render() {
      const newProps = {
        name: {
          value: this.state.name,
          onChange: this.onNameChange
        }
      }
      return <WrappedComponent {...this.props} {...newProps}/>
    }
  }
}

```

使用方法如下:

```js
@ppHOC
class Example extends React.Component {
  render() {
    return <input name="name" {...this.props.name}/>
  }
}
```

通过抽象 state, 把包装组件和 props,method 就分离开了

##### 可以用其他的元素包裹包装组件

例如可以提供样式

```js
function ppHOC(WrappedComponent) {
  return class PP extends React.Component {
    render() {
      return (
        <div style={{display: 'block'}}>
          <WrappedComponent {...this.props}/>
        </div>
      )
    }
  }
}
```

#### 继承反转 
这个没看懂
```
function iiHOC(WrappedComponent) {
  return class Enhancer extends WrappedComponent {
    render() {
      return super.render()
    }
  }
}
```








 

