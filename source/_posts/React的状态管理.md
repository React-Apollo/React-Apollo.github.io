---
title:  React的状态管理
date: 2019-04-22 15:10
categories: 技术备忘
tags: [Javascript,React,React-Hooks,Redux]
---


> 主要内容,看看State的状态管理方式,包括最基本的方式和React-Hooks方式以及Redux方式和ReSub方式

 **我们从基本的方式开始**
 ## React和数据的基本交互方式
 
 在MVC程序构架中,React经常被称为`View`层,但实际上并不王权是这样, React实际对MVC模式做了新的构想. 本质上React只是借助JSX语法实现的UI界面库,但是UI都需要数据来填充,所以问题就是如何获取数据,如何灵活的展现数据.
 
 
 ### MVC的思想
 
 MVC架构的基本思想:
 - 模型层(Model)就是数据层.
 - 视图层(View)负责整个应用程序的展示.
 - 控制层(Controller)在应用程序中扶着提供数据处理的逻辑操作.

React处理数据和MVC有微妙的区别. 在由多个子组件组合而成的视图(父组件)里, 子组件可以管理自己的数据处理方式,而且也可以从父组件获取数据,只需要在父组件中提供一个控制器就可以了. 
### React的思想

在React的组件中有两种不同的数据类型:

- `props` ,在创建组件的时候,`props`会作为参数传递给组件,这个就作为组件顶级的配置项,一旦定义好,组件就不能自行修改了. 在React定的父组件->子组件的信息传递中,只能使用这一种方式.没有其他的方法. Props是`React组件库`的精华, 我们可以定义不同的Props来控制组件的表现形式. 

- `state`,state是组件内部的数据.React的精华实际就在state上,我们可以在父组件中定义一个state,然后以Props的形式传递给子组件, state只是一个JS对象,我们可以定义任何形式的属性. state的定义多样性,决定了你的应用的多样性. 通过定义组件的state,可以实现基本的状态管理,也可以实现类Redux管理方式, 还可以实现React-Hooks的管理方式. 如果深入一点,你需要知道,Redux其实就是一个只有State逻辑处理而没有UI的React组件. 
   
   
   进行State修改的方法就只有一个 `this.setState({})`.在Redux这个特殊的React组件中,也是通过这个方法来修改App的State,只不过我们看不到实现细节. 后续我会通过一个表单来看看看里面具体的实现.
   
   以上内容整理自F8-App的介绍,但是掀
   
## 基本实现

State设计是React应用最重要的部分.这个设计,我认为也是React思想建立的关键. 核心是`如何思考State的提升`, 也就是不断的把State提升到更高一级的组件中. 但是这个提升也要适可而止, 应该总是以具体的处理流程作为分割线. 同一个流程的State,最终可以提升为一个总的State,例如和登录,注册,登出,找回密码和修改密码的流程,就可以提升为一个大的State. `不相关流程的State,就不要混合在一起`.不管你是使用基础的State管理,Redux管理,Hooks管理,包括ReSub,这一点都是一样的.   

### React文档中的基本处理方法

`单个字段的‌表单`

```javascript
class SingleFieldForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {value: ''};

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(event) {
    this.setState({value: event.target.value});
  }

  handleSubmit(event) {
    alert('A name was submitted: ' + this.state.value);
    event.preventDefault();
  }

  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <label>
          Name:
          <input type="text" value={this.state.value} onChange={this.handleChange} />
        </label>
        <input type="submit" value="Submit" />
      </form>
    );
  }
}
```
   
这是一个简单的表单组件,要实现这个表单,不仅要使用state,还有props,同时还要有展示内容的UI组件

在表单组件中定义了state:

```javascript
//只是一个JS对象,属性名为value
this.state = {value: ''};
```

定义了处理state的方法:

```javascript
handleChange(event) {
    this.setState({value: event.target.value});
  }

  handleSubmit(event) {
    alert('A name was submitted: ' + this.state.value);
    event.preventDefault();
  }

```

在创建一个表单组件的时候,需要反馈给输入用户到底自己输入的是什么,还有如何进行表单提交的方法.上面两段代码就定义这两个内容. 那么表单组件内部的子组件直接获取输入的内容和提交方法就可以了.从父组件向子组件传递数据时,我们就需要用到props.就是下面的代码

```javascript
<form onSubmit={this.handleSubmit}>
        <label>
          Name:
          <input type="text" value={this.state.value} onChange={this.handleChange} />
        </label>
        <input type="submit" value="Submit" />
      </form>
```

这里的`form`,`input[type="text"]`,`input[type="submit"]` 都是props的用法.  这里只要牢记一点, 在return中出现的所有参数都是props, render之外的是state,

```javascript
 render(){
 return(
    ...code
 )
 
```

在JS中,我们是传引用赋值的,所以在子组件就可以通过引用的方法名来操作父组件定义的State, 那么这里就有一个问题, 如果我们继续把父组件中定义的State和State处理方法提升的爷爷组件,在继续提升的太爷爷组件上,应该是一样的吧?  我可以确切的说, React的代码编写就是这个原则. 只不过state的设计需要稍稍复杂一点.


如果是多个字段的表单,我们应该如何编写代码?

如果按照常规是这样的
`‌多字段表单常规写法`

```javascript
class ThreeFieldsForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {name: ''
                  age: null,
                  email:''
     };

    this.handleNameChange = this.handleNameChange.bind(this);
    this.handleAgeChange = this.handleAgeChange.bind(this);
    this.handleEmailChange = this.handleEmailChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleNameChange(event) {
    this.setState({name: event.target.value});
  }
  
  handleAgeChange(event) {
    this.setState({age: event.target.value});
  }
  handleEmailChange(event) {
    this.setState({email: event.target.value});
  }

  handleSubmit(event) {
    alert('A name was submitted: ' + this.state.value);
    event.preventDefault();
  }

  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <label>
          Name:
          <input type="text" value={this.state.name} onChange={(event)=>this.handleNameChange(event.target.value)} />
        </label>
        <label>
           Age:
          <input type="text" value={this.state.age} onChange={this.handleAgeChange} />
        </label>

<label>
          Email:
          <input type="text" value={this.state.email} onChange={this.handleEmailChange} />
        </label>

        <input type="submit" value="Submit" />
      </form>
    );
  }
}
```


这里是三个字段的表单, 如果是十个字段, 那么state和处理方法代码就太多了, 并且你发现这些代码只有一个地方是不同,或许我们可以在state处理方法上想想办法?


`‌把handleChange方法抽象出来`

```javascript
class ThreeFieldsForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {name: ''
                  age: null,
                  email:''
     };

       
    
    
  }
  //这里用了ES6的箭头函数就不需要再绑定啦
  setValue = (type, text) => {
    switch (type) {
      case "setName":
        this.setState({ name: text });
        break;
      case "setAge":
        this.setState({ age: text });
        break;
      case "setEmail":
        this.setState({ email: text });
        break;
      
    }
  };

  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <label>
          Name:
          <input type="text" 
             type="setName"
            onChange={(event)=>this.setValue(event.target.value,"setName")}
            value={this.state.name} />
        </label>
        <label>
           Age:
          <input type="text" 
          type="setAge"
           onChange={(event)=>this.setValue(event.target.value,"setAge")}
          value={this.state.age} />
        </label>

<label>
          Email:
          <input type="text" 
          type="setEmail"
          onChange={(event)=>this.setValue(event.target.value,"setEmail")}
          value={this.state.age} />
        </label>

        <input type="submit" value="Submit" />
      </form>
    );
  }
}
```

这里有两个词,如果你看了Redux和React-Hooks,可能会觉得很眼熟,  一个是`type`,另一个是`setValue`,   **`没错这个地方也是我写这篇文章的着眼点`**,上周我想到这个地方的的时候,就觉得常规的State处理,Redux和React-hooks对于State的处理其实并没有明确的界限. 如何使用就是React程序员需要考虑的问题. 

如果这个表单用React-Hooks处理是这个样子的

```javascript
import {useState}  from 'React';

 const  ThreeFieldForm=(props)=>{
    const [name,setName]=useState("");
    const [age,setAge]=useState(null);
    const  [email,setEmail]=useState("")
  return (
      <form onSubmit={this.handleSubmit}>
        <label>
          Name:
          <input type="text" 
             type="setName"
            onChange={(event)=>setName(event.target.value)}
            value={this.state.name} />
        </label>
        <label>
           Age:
          <input type="text" 
          type="setAge"
           onChange={(event)=>setAge(event.target.value)}
          value={this.state.age} />
        </label>

<label>
          Email:
          <input type="text" 
          type="setEmail"
          onChange={(event)=>this.setEmail(event.target.value)}
          value={this.state.age} />
        </label>

        <input type="submit" value="Submit" />
      </form>
    );
}

```


如果我们在处理的方法中加了`type`那就可以用`useReducer`啦! useReducer可以看下面这段代码.

`useReducer`


```
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


这里的这段代码,我们先不作解释,如果对Redux比较理解了, useReducer的方法也是比较好理解的. 还是之前提到的那一句话, state的管理方法不是绝对的, 看看如何思考具体的是用. 经过之前的提升操作, 如果更进一步,把所有的state都提升到一个顶级的组件中, Redux模式就完成了.  这一点我在后面会继续讲到, 其实在很多讲解Redux的图示中,都会提到数据单向流动, 没错一旦所有的State都提升到顶级的组件中, 数据就只能通过`props`的形式传递给子组件. 最大的子组件就是Redux的包装下的那个App组件.

如果你看过Redux的模型图,例如下面这一张:

![](https://ws2.sinaimg.cn/large/006tNc79gy1g2bggqs6qnj30zk0qomzw.jpg)

或者我自己画的
![](https://ws1.sinaimg.cn/large/006tNc79gy1g2bgoh4mmpj30s40cykav.jpg)


数据是单向流动的,从React-Redux组件流向应用的组件. 
但是在第一张图的右侧的Actions似乎有流了回去, 这算是单向流动吗? 
这个问题时间用dispatch并不好理解, 用ReSub的触发似乎要好一点.
后边我会结合一个自己想的现实生活中的实例来解释这个问题. 

下面我要声明我自己的一个学习体会, React经过几年的高速发展, 构架不断的向函数式编程方向发展, 函数式组件内部的JSX代码结合传入的数据,我们想要的应用就实现了. 
所以归结为两点一个是函数式组件,另外一个就是数据. 在React中流动的数据仅仅只是JS对象,如果我们给这些对象添加了定义好了`Type`类型,那么数据就可以井然有序的呗管理和组织,就是这么简洁,注意是简洁并不是简单, 要想设计好State也不是一件容易的事情. 
下面我们要进入本文的主题了, 通俗的学习Redux.

## React的状态管理的权威-Redux
这里我不想很正式的讲解Redux,Redux文档写的非常好,可能一开始看觉得很难,但是看过十几遍之后,你会觉得甘之如饴. 没有看十遍以上的,是苦的.
所以我想换个方法, 用通俗的方法来解释一下,这个问题.作为看文档的补充.很多时候看问题要换个角度,或者换个容易理解的模型就比较容易理解了. 
### Redux的通俗理解
我们就从 这张图的`Store`开始
![](https://ws2.sinaimg.cn/large/006tNc79gy1g2bggqs6qnj30zk0qomzw.jpg)


这一段时间我都在思考Redux Store的通俗理解方法. 结果发现本身这个单词就是最好的诠释. 

这里的Store我想用两个模型解释,一个是沃尔玛的Super Store,一个是电商的Store,就拿JD商城做例子吧.
#### 从Store开始.
##### 沃尔玛的Store
如果你没去过沃尔玛,把沃尔玛换成全家便利店也可以, 规模不同,结构和组织完全相同.
但是如果类比Redux的Store,大型超市的多人管理更类似些

在Store里,首先你会看大很多的货架,一个Store在刚开始初始化的时候是这个样子的

![Store初始化的货架](https://ws3.sinaimg.cn/large/006tNc79gy1g2bhblvz70j30hs0dagn4.jpg)

开张的时候是这个样子的:
![Store的货架摆满货物](https://ws2.sinaimg.cn/large/006tNc79gy1g2bhd3b3fxj30sg0lcn4n.jpg)


基本大型超市会分成不同的楼层,然后分成不同的区域,不同的货架 处理具体货架的人是不同的,所以尽管很大,但是由于进行了分区,分层处理,管理是井井有条的.每个区域,每个分类,每个货架都有不同的标签来标识. 每种货物的具体补货,出货,换货等方法都相应的不同, 但是只要找到具体每个区的负责员工就可以实现了. 看这个每天超市庞大的货物吞吐量, 其实进入到超市之后,就想看不见的洋流一样其实是在各自区域中独立的流动.

与之对照, 在Redux中所有的应用State,初看起来也是非常庞大,但是具体到实现,都由JS对象的键类区分和管理,各自也包含了自己的State处理方法. 每个小部分的对象和处理方法就统称为`reducer`,每个小分区的State又通过 CombineReducer组合成最大的Reducer,我们可以从整个Reducer里获取到应用的完整State. 我们去超市,抽象的是和超市打交道,具体的是和每个终端在员工和货架在打交道. 所以尽管超市很大,但是处理问题的方式却很简单.

##### 京东的Store

京东的Store,和我们React里的Store就非常接近了.  之所以拿电商来做实际的例子,要解决三个问题,一是如何理解Redux的 `dispatch`方法,另一个是如何理解`connect`. 这里我先做一个通俗的解释,然后讲解一张我认为对这个模式解释最好的图片.还有就是数据的不可突变性

`dispatch`

`dispatch`时,到底有没有数据从用户流向Store? 这个单词翻译为中文叫分派,似乎还不太准确,准确的翻译应该叫触发. ReSub这个库就用了`trigger`这个词. 最好的处理就是把state和处理state的方法统一放大一个地方. 由于JS是传引用赋值的,我们可以把修改State的方法通过`props`的形式传递给子组件, 子组件只需要触发对应的操作就可以了.所以这里用触发的解释比较好. 面对一个庞大的电商Store,也没有什么担心的,只要定义好了不会引发歧义的`type`就可以了.  我们触发一个操作,就是执行一个Store定义的方法,根据触发的type对Redux的State做出修改.

我们在京东购物时,点击购买,提交的就是商品品名,数量,此外我们还要提供自己的地址,相当于为自己的地址绑定了这次购物,等物品从JD的Store出来之后,后按照你的地址进行派送. 整个流程几乎是完全相同的.

`connect`

从JD Store出来的货物是针对全部买家的,不是每件商品都是你需要的. 所以当Store的货物返回到社会以后,需要根据买家的地址来进行筛选和分类,然后由快递员按你提供的地址进行派送. 这个过程是自动, 你不需要自己动手, 因为之前已经进行了订阅.

用Redux的方法就是使用`mapStateToProps`把某个组件需要的数据筛选出来. 
由于需要`dispatch`的Store方法也是从外部传递的,所有就有了`mapDispatchToProps`方法, 传递Store对应的方法名. 在重复一下, 组件外部的数据只能通过`props`传递. 


好了时候借用别人的杀手锏了. 
下面这张图嘛,你可以想象是你有几个朋友,分别在不同的城市,你用他们的地址进行了订阅,然后你在JD上提交了订单,触发了JD  Store的一次操作,然后JD根据你的订阅地址把货物发送到几个朋友手中.

![](https://ws1.sinaimg.cn/large/006tNc79gy1foy0b5c2t2g30jg0d7b29.gif)
图片出处 [when-do-i-know-im-ready-for-redux](https://medium.com/dailyjs/when-do-i-know-im-ready-for-redux-f34da253c85f)

你现在可以进入这张图中,你的家就在最右边的这个球中,你触发了一个订购操作,比如
在`2019年4月22号20点20分20秒195毫秒时`
订购了三只中华铅笔,HB的.
然后JD的的文具分部接受根据你触发的动作的类型做了相应的处理,通知Store出货,然后铅笔库存减掉3, 这时如果还有其他人想买中华的HB铅笔,就会显示无货. 你的这次订阅和小米的旗舰店没有任何的关联, 尽管从外面看JD的铅笔和小米的手机是从同一个地方出来的,但是在Store内部是由不同的分支来处理的.

上面我专门添加了一个时间,是为了要解决数据的不可变性这个问题,就是在Redux文档中提到的时间旅行的问题. 

数据的不可突变性对于JavaScript是一个问题,但是对于某些语言就不是问题. JS中的这个问题是由于JS对于数据存储的方法引起的.



`例如我们要在JS中定义一个蜡笔的颜色为红色:`

![定义一个红色蜡笔颜色](https://ws3.sinaimg.cn/large/006tNc79gy1g2bjdjd7o2j310k0u0myy.jpg)

`然后我们把对象变为蓝色的对象, JS会为这个对象重新分配内存地址`

![修改蜡笔为蓝色颜色对象](https://ws1.sinaimg.cn/large/006tNc79gy1g2bjeri62jj30u012q42s.jpg)


`但是如果我们只修改对象的属性,问题就来了,JS会在原位置对对象作出修改`

![修改蜡笔的颜色属性](https://ws3.sinaimg.cn/large/006tNc79gy1g2bjh616p8j30uk0u0n0a.jpg)


由于Redux Store中的state是嵌套对象, 如果对某一部分属性进行修改, 内存地址不会发生改变, Store可能认为你没有做什么修改工作,因为在Store中使用'==='来决定state是否发生改变的.`===`符号在JS中就是比较对象的内存地址的. 
所以在Redux中需要手动把要修改的State复制到新的内存地址中,然后在做修改,从而让Store可以觉察到State的变化. 

`以上解释来自[Immutability in React and Redux: The Complete Guide](https://daveceddia.com/react-redux-immutability-guide/).
如果理解有偏差,敬请指出`

但是这样做每次修改都要开辟新的内存地址, 是比较浪费内存的.所以FaceBook提出了 Immutable.js 的方法.  这就是我上面用到的那个时间段的意思. 还是在JD的Store, 我们要出货,管理库存,当用户订购了三只中华铅笔,库存要减掉, 我们可以把所有的库存账本重新抄一遍,然后把中华铅笔的库存减掉3.但是实际的库存管理不是这样做的, 我们有一个总的库存目录, 然后单独在一个地方记载某个时间某个商品的库存发生了什么变化, 没有变化的部分,就不管了.  这就是Immutable的处理方法. 记载变化的位置,共享不变的位置. 如果我们不为修改打上时间戳就没有办法知道历史记录了,因为历史数据被新的数据给替换掉了. 所以实际的账目中不仅要记录账目发生变化的品名还要记录时间. Redux的时间旅行就是这个意思.

上面的那篇文章对于JS的Immutability操作解释的非常好, 我也准备翻译. 尤其是后面的Immer库很方便.

`未完成,还有一些内容`






