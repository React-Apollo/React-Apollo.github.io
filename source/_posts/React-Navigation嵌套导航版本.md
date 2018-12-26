title: React Navigation导航的模板
date: 2018-02-01 10:20:45
categories: 技术备忘
tags: [React-native]
---

## 根据 GitPoint来的多层嵌套的导航版本

大体的路径是  进入 splash 界面, componentDidMount 周期中对用于登录信息进行查找和判断,如果是为登录就跳到登录界面,如果登录就跳到主界面
这个三个文件作为入口的 StackNavigator:

```js
//这个文件单独建立, route.js,在 app.js 中 导入 NavEntryPoint 就可以了
export const NavEntryPoint = StackNavigator(
  {
    Splash: {
      screen: SplashScreen,
      navigationOptions: {
        header: null,
      },
    },
    Login: {
      screen: LoginScreen,
      navigationOptions: {
        header: null,
      },
    },
    Main: {
      screen: MainTabNavigator,
      navigationOptions: {
        header: null,
      },
    },
  },
  {
    headerMode: 'screen',
    URIPrefix: 'gitpoint://',
    cardStyle: {
      backgroundColor: '#c397d8',
    },
  }
);
```

login如果登录成功,也跳转到主界面

### 主界面TabNavigator

主界面是 TabNavigator,由单独的 StackNavigator 构成

```js
const  MainTabNavigator=TabNavigator({
    Home: {
      screen: HomeStackNavigator,
      navigationOptions: {
        tabBarLabel: 'Home',
        tabBarIcon: ({ tintColor, focused }) => (
          <Image  source={focused?require('./app/assets/tabs/tab-icon1/active.png'):require('./app/assets/tabs/tab-icon1/default.png')} />
        ),header: null,
  
      },
    },
    About:{
      screen :AboutStackNavigator,
        navigationOptions: {
        tabBarLabel: 'About',
        tabBarIcon: ({ tintColor, focused }) => (
          <Image  source={focused?require('./app/assets/tabs/tab-icon2/active.png'):require('./app/assets/tabs/tab-icon2/default.png')} />
        ),header: null,
      },
    },
    Contact:{
      screen :ContactStackNavigator,
        navigationOptions: {
        tabBarLabel: 'Contact',
        tabBarIcon: ({ tintColor, focused }) => (
          <Image  source={focused?require('./app/assets/tabs/tab-icon5/active.png'):require('./app/assets/tabs/tab-icon5/default.png')} />
        ),header: null,
      },
    },
    More:{
      screen :MoreStackNavigator,
        navigationOptions: {
        tabBarLabel: 'More',
        tabBarIcon: ({ tintColor, focused }) => (
          <Image  source={focused?require('./app/assets/tabs/tab-icon3/active.png'):require('./app/assets/tabs/tab-icon3/default.png')} />
        ),header: null,
      },
    },
    
  }, {
    tabBarPosition: 'bottom',
    animationEnabled: false,
    tabBarOptions: {
      activeTintColor: '#e91e63',
    },
  })

```

`以上两部分,定制好以后,就可以不动了`,主要的页面的添加都是在四个 StackNavigator 中进行的. 

### `承载主要功能页面`的StackNavigator

```js
import {tab1,list1 } from './app/tab1';
const HomeStackNavigator = StackNavigator(
  {
    Home: {
      screen: tab1,
      navigationOptions: {
        headerTitle: 'Tab1',
      },
    },
    List1: {
        screen: list1,
        navigationOptions: {
          headerTitle: 'list1',
        },
      },
    
  },
  {
    headerMode: 'screen',
  }
);
```

`每个Tab 下的功能就在这里扩展`,按照 GitPoint 的思路,有一些公共的页面,可以用 shareRoute 的形式,导入到单个 Tab的 StackNavigator下面.

**这就是完整的 React Navigation嵌套导航的模板,基本的 APP都可以直接套用了**