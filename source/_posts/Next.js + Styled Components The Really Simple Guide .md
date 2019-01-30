



---
title: 摘要|Next.js + Styled Components The Really Simple Guide 
date: 2019-01-30 21:59
categories: 技术备忘
tags: [React,Next.js]
---

<script src="https://cdn.bootcss.com/mathjax/2.7.5/latest.js"></script>
{{TOC}}


> [`原文参见`](https://dev.to/aprietof/nextjs--styled-components-the-really-simple-guide----101c)
>Next.js自带了styled-jsx的css方法。在Next的实例中有with-styled-components的实例，但是我们需要理解是怎么构建出实例的。


## 具体构建过程

### 1. 创建项目目录，安装依赖包

```bash
mkdir my-next-app &&cd my-next-app &&yarn add next react ract-dom
```

>Next.js 现在支持React 16版本


### 2. 在package.json文件中添加脚本

```json
{
  "scripts": {
    "dev": "next",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^...",
    "react": "^...",
    "react-dom": "^..."
  }
}
```


完成这一步之后，文件系统就是主要的API 入口。 每个`.js`文件都成为自动处理和渲染的路由。

### 3. 创建一个/pages 文件夹，建立第一个页面

```bash
mkdir pages&& touch pages/index.js
```


编写`./pages/index.js`文件

```js
Export default ()=>{
   <div>
      <h1> My First Next.js Page </h1>
   </div>
}

```


然后在终端中运行命令 `yarn dev`,浏览器打开`http://localhost:3000`


截止目前，我们建立了：

- 自动编译和绑定(借助webpack和babel)
- 代码热加载
- 服务端渲染和`./pages`的索引文件

### 4. 添加styled-components组件包

```bash
yarn add styled-components
```

现在编辑`./pages/index.js`文件

```javascript
Import styled from 'styled-components';
Export default ()=>{
   <div>
   
      <Title> My First Next.js Pages</Title>
   </div>
};

const Title=styled.h1`
  color: red;
`
```


如果加载文件，会报错，因为配置不正确。接下来完成这一步

### 5. 添加 babel 插件，定制 `.bablerc`文件 

首先安装styled components bable插件

```bash
yarn  add -D babel-plugin-styled-components

```

在项目的根目录下创建 `.babelrc`文件

```bash
touch .babelrc
```

- 添加 babel/preset
- 添加styled-components插件，设置ssr 标记为 `true`,`displayName`为 `true`,`preprocess` 为`false`.

最后得到的`.babelrc`文件如下

```.babelrc
{
  "presets": [
    "next/babel"
  ],
  "plugins": [
    [
      "styled-components",
      {
        "ssr": true,
        "displayName": true,
        "preprocess": false
      }
    ]
  ]
}
```


### 6.创建定制的 `_document.js`文件

如果你之前使用过`create-react-app`,你就知道主文件在哪里，但是next.js不会暴露出这个文件，但是你可通过添加 `_document.js`文件来覆盖默认的Document。

```bash
Touch pages/_document.js
```

我们要扩充 `<Document>`,并把服务端渲染的样式注入到`<head>`中。

如果只渲染page，不做其他工作，`_document.js`文件如下：


```javascritpt
import Document, { Head, Main, NextScript } from 'next/document'

export default class MyDocument extends Document {
  static getInitialProps ({ renderPage }) {
    // Returns an object like: { html, head, errorHtml, chunks, styles }     
    return renderPage();
  }

  render () {    
    return (
      <html>
        <Head>
          <title>My page</title>
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </html>
    )
  }
}
```


添加进styled-components的代码如下：


```javascript
import Document, { Head, Main, NextScript } from 'next/document';
// Import styled components ServerStyleSheet
import { ServerStyleSheet } from 'styled-components';

export default class MyDocument extends Document {
  static getInitialProps({ renderPage }) {
    // Step 1: Create an instance of ServerStyleSheet
    const sheet = new ServerStyleSheet();

    // Step 2: Retrieve styles from components in the page
    const page = renderPage((App) => (props) =>
      sheet.collectStyles(<App {...props} />),
    );

    // Step 3: Extract the styles as <style> tags
    const styleTags = sheet.getStyleElement();

    // Step 4: Pass styleTags as a prop
    return { ...page, styleTags };
  }

  render() {
    return (
      <html>
        <Head>
          <title>My page</title>
          {/* Step 5: Output the styles in the head  */}
          {this.props.styleTags}
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </html>
    );
  }
}
```


添加完成之后，重启服务器，之前的错误就没有了，`<h1>`标签应该是红色的。 SSR 的styled-components工作正常了

回顾一下步骤

1.  创建项目，安装依赖包
2.  添加脚本
3.  创建page文件夹和第一个页面文件
4.  添加styled-components
5.  天剑babel插件，并定制`.babelrc`文件
6.  创建定制的 `_document.js`文件

如果你已经有了next项目， 需要实现4-6步。
这也是在next.js中使用`.css`文件的方法。


