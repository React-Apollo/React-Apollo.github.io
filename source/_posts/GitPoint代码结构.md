---
title:  GitPoint代码结构
date: 2019-02-14 09:39
categories: 技术备忘
tags: [React-Native,Redux，styled-compoents]
---

{{TOC}}

 

##  简介 

React的16.8.1的版本已经发布，在稍后的React-Native的0.59版本会支持React-Hooks这个特性。 经过之间一段时间的学习，对React的函数式编程方式有了一定的了解。刚好遇到React-Hooks发布。 学习了一些Hook上的使用方法。由衷的感慨，React向函数式组件的进化让编程变得非常有意思。

之前看过了GitPoint代码，由于代码结构比较复杂，所以似懂非懂的。
又翻出来看，发现GitPoint的技术栈和我之前学习积累的方法已经很接近了。 

**理想的RN技术栈包括如下的技术：**

- React,React-hooks  数据管理
- Functional Components   APP组织
- Apollo    异步操作 GraphQL  client
- Styled-Components  函数式CSS,
- Typescript   类型检查
- React-Navigation 用于导航

**GitPoint目前的技术栈**：

-  React,Redux  数据管理
-  Class Components   APP组织
-  GraphQL,      异步操作 Client
-  Styled-Components   函数式样式
-  Flow    类型检查
-  React-Navigation  导航


> 目的就是想看看从目前的技术栈迁移到理想的技术栈的可行性。
> 对于这个APP,对远程数据的需要比本地的交互操作内容要多得的，
> Redux结构就稍显复杂，但是React-Hooks的useState ,useEffects和useReducer原理和Redux是完全一样的，之前需要把所有的Reducer合并(combineReducer)一起，现在就不用了， 单个的功能组件管理自己的reducer, 如果是全局的state，可以使用useContext方法， 还要两个论坛包装的方法，也可以在全局使用。 原则就是：`‌数据的Immutable`,`数据的单向流动`。 
###   遵循的原则
 1. 数据的Immutable
    现在可以借助新的 Immer 使得 Immutable的操作简单化
 2. 数据单相流动，
     对于函数式组件，完全不是问题，因为 函数式组件的数据天然是通过函数的参数传入。
    

## 项目结构
### 基本结构



 ![](https://ws4.sinaimg.cn/large/006tKfTcgy1g05qzkfrgoj30ji0s4q76.jpg) 

- 🔘 `app.js` :入口文件
- 🔘 `routes.js`: 路由总文件
- 🔘 `root.store.js`: redux的store文件
- 🔘  `root-reducer.js`： redux的reducer的combine文件
- 🔘 `.flowconfig`: flow类型检查的配置文件
- 🔘 `./src` ：程序文件夹

### 入口文件 app.jsx
**`‌静态方法获取当前位置`**

因为GitPoint App支持多种语言的本地化，在这里获取地理位置之后，后面的界面可以加载不同的文字


```jsx
static async initLocale() {
    //获取当前位置
    const locale = await getCurrentLocale();
    //配置当前位置，根据当前位置来设置App本地化信息
    configureLocale(locale);
  }
```

**`constructor`**

 使用`redux-persist` 保存Redux state至本地。在程序启动时需要判读`state`读取是否完成，或者是第一个使用，`state`为`null`.
 

```jsx
constructor() {
    super();

    this.state = {
      rehydrated: false,  
    };
    this.statusBarHandler = this.statusBarHandler.bind(this);
  }
```

**`componentWillMount()`**

在组件挂在周期函数中获取state加密方法，从本地获取state,设置`rehydrated:true` ,标识state加载完毕

```jsx
componentWillMount() {
    const encryptor = createEncryptor({
      secretKey: md5(DeviceInfo.getUniqueID()),
    });

    persistStore(
      configureStore,
      {
        storage: AsyncStorage,
        transforms: [encryptor],
        whitelist: ['auth'],
      },
      () => {
        this.setState({ rehydrated: true });
      }
    );

    this.constructor.initLocale();
  }
```


**`render（）`**

render方法要根据rehydrated的状态加载不同的组件
如果为`false` 加载splash界面

如果为`true`，跳转到React-Navigation的主路由

```jsx
render() {
    if (!this.state.rehydrated) {
      return (
        <Container>
          <Logo source={require('./src/assets/logo-black.png')} />
        </Container>
      );
    }
      //如果已经登录、就返回Redux store包装的主程序界面
      //gitpoint主程序有React-Navigation来执行路由导航任务
    return (
      <Provider store={configureStore}>
        <GitPoint onNavigationStateChange={this.statusBarHandler}>
          <StatusBar />
        </GitPoint>
      </Provider>
    );
    
```



### `routes.js`总路由文件

- `Splash` 页面  启动页  
- `Login`  页面  加载了github的第三方登录web页面和一个
- `Welcome` 页面
- `Main`  实际应用的路由

这四个路由使用堆栈来存放，实际的处理就是按顺序执行， 如果Longin没有完成，无法进入到Welcome的界面和Main的界面

#### `Main`路由的组织

`Main`路由是登录以后的实际路由，分为两大块， 根据BottomTab组织的Tab路由分为：

-  `Home`
-  `Notification`
-  `‌Search`
-  `User`

路由的安排和Redux中的Reducer的组织是一样方式，就是按照这个Tab的结构来安排， Tab就是APP的具体内容. 每个Tab中的页面是使用StackNavigator来组织的

还有一些可以共用的页面单独存放，压入到单个的Tab中。

```jsx
const MyProfileStackNavigator = StackNavigator(
  {
    MyProfile: {
      screen: AuthProfileScreen,
      navigationOptions: {
        header: null,
      },
    },
    ...sharedRoutes,
  },
  {
    headerMode: 'screen',
  }
);

const MainTabNavigator = TabNavigator(
  {
    Home: {
      screen: HomeStackNavigator,
      navigationOptions: {
        tabBarIcon: ({ tintColor }) => (
          <Icon
            containerStyle={{ justifyContent: 'center', alignItems: 'center' }}
            color={tintColor}
            name="home"
            size={33}
          />
        ),
      },
    },
    Notifications: {
      screen: NotificationsStackNavigator,
      navigationOptions: {
        tabBarIcon: ({ tintColor }) => (
          <NotificationIcon iconColor={tintColor} />
        ),
      },
    },
    Search: {
      screen: SearchStackNavigator,
      navigationOptions: {
        tabBarIcon: ({ tintColor }) => (
          <Icon
            containerStyle={{ justifyContent: 'center', alignItems: 'center' }}
            color={tintColor}
            name="search"
            size={33}
          />
        ),
      },
    },
    MyProfile: {
      screen: MyProfileStackNavigator,
      navigationOptions: {
        tabBarIcon: ({ tintColor }) => (
          <Icon
            containerStyle={{ justifyContent: 'center', alignItems: 'center' }}
            color={tintColor}
            name="person"
            size={33}
          />
        ),
      },
    },
  },
  {
    lazy: true,
    tabBarPosition: 'bottom',
    tabBarOptions: {
      showLabel: false,
      activeTintColor: colors.primaryDark,
      inactiveTintColor: colors.grey,
      style: {
        backgroundColor: colors.alabaster,
      },
    },
    tabBarComponent: ({ jumpToIndex, ...props }) => (
      <TabBarBottom
        {...props}
        jumpToIndex={index => {
          const { dispatch, state } = props.navigation;

          if (state.index === index && state.routes[index].routes.length > 1) {
            const stackRouteName = [
              'Events',
              'Notifications',
              'Search',
              'MyProfile',
            ][index];

            dispatch(
              NavigationActions.reset({
                index: 0,
                actions: [
                  NavigationActions.navigate({ routeName: stackRouteName }),
                ],
              })
            );
          } else {
            jumpToIndex(index);
          }
        }}
      />
    ),
  }
  
```

在最新版本的 React-Navigtion中，TabBarBottom的配置非常简单。需要做更新。


## 实际应用代码

![](https://ws1.sinaimg.cn/large/006tKfTcgy1g05v782ifcj30pe0eyae5.jpg)

### Splash页面
判断用户是否登录，如果登录跳转的Main路由，如果没有登录过，跳转到登录页面.Splash页面不属于应用的流程， 只是从store获取登录状态，


```
//通过react-redux mapStateToProps方法从store获取认证信息
const mapStateToProps = state => ({
  isAuthenticated: state.auth.isAuthenticated,
});


//render方法加载  Logo

render() {
    return (
      <LogoContainer>
        <Logo source={require('../../assets/logo-black.png')} />
      </LogoContainer>
    );
  }

// cdm方法根据isAuthenicated状态决定跳转到那个页面

componentDidMount() {
    const { isAuthenticated, navigation } = this.props;
  //如果登录直接跳转到主界面
    if (isAuthenticated) {
      resetNavigationTo('Main', navigation);
    } else {
      resetNavigationTo('Login', navigation);
    }
  }
```


### 登录流程
####  Login.screen.js

```js
从state获取的信息
const mapStateToProps = state => ({
  locale: state.auth.locale,
  isLoggingIn: state.auth.isLoggingIn,
  isAuthenticated: state.auth.isAuthenticated,
  hasInitialUser: state.auth.hasInitialUser,
});
//dispactch的方法，
const mapDispatchToProps = dispatch =>
  bindActionCreators(
    {
      auth,
      getUser,
    },
    dispatch
  );
```


在gitPoint中，文件的组织是按照Tab来分类的，每个Tab是一个独立的应用流程。 在独立的流程文件夹中保存了Redux的结构， 容器组件和展示组件没有分开， *.action.js ，*.reducer.js ，*.selector.js , *.type.js 文件  位于同一个流程中， 管理起来非常方便。 在Redux内部，每个应用的流程是独立的。一开始学习是感到困惑的CombineReducer，其实只是简单的把reducer合并起来。只要不违反 Redux的三个原则， 文件组织结构可以是很灵活的。 GitPoint的组织结构迁移到React-Hooks模式，将会非常方便。

未登录时，跳转到github登录页面，如果登录成功，会返回状态和代码,state,code。根据这两个返回结构来执行下面的操作

```
//login.screen.js

handleOpenURL = ({ url }) => {
    if (url && url.substring(0, 11) === 'gitpoint://') {
      const [, queryStringFromUrl] = url.match(/\?(.*)/);
      const { state, code } = queryString.parse(queryStringFromUrl);
      const { auth, getUser, navigation, locale } = this.props;

      if (stateRandom === state) {
        this.setState({
          code,
          showLoader: true,
          loaderText: t('Preparing GitPoint...', locale),
        });

        stateRandom = Math.random().toString();
       
        CookieManager.clearAll().then(() => {
          
          auth(code, state).then(() =>{//redux  action
            getUser().then(() => { 
              resetNavigationTo('Main', navigation);
            });
          });
        });
      }
    }
  };
```


在auth.action.js中执行的auth方法

```js
//auth.action.js

//首先获取用户的Token
export const auth = (code, state) => {
  return dispatch => {
    dispatch({ type: LOGIN.PENDING });

    return delay(fetchAccessToken(code, state), 2000)
      .then(data => {
        dispatch({
          type: LOGIN.SUCCESS,
          payload: data.access_token,
        });
      })
      .catch(error => {
        dispatch({
          type: LOGIN.ERROR,
          payload: error,
        });
      });
  };
};


//根据Token获取用户信息

export const getUser = () => {
  return (dispatch, getState) => {
    const accessToken = getState().auth.accessToken;

    dispatch({ type: GET_AUTH_USER.PENDING });

    return fetchAuthUser(accessToken)
      .then(data => {
        dispatch({
          type: GET_AUTH_USER.SUCCESS,
          payload: data,
        });
      })
      .catch(error => {
        dispatch({
          type: GET_AUTH_USER.ERROR,
          payload: error,
        });
      });
  };
};
```

与用户相关的流程都放在这里， 其他的信息是通过GraphQL来获取的。

####  `action.type.js`

在执行异步操作的action时，需要标识状态， GitPoint使用了 `action-helper.js`中的createActionSet来生成多个方法 

```js
export const createActionSet = actionName => ({
  PENDING: `${actionName}_PENDING`,
  SUCCESS: `${actionName}_SUCCESS`,
  ERROR: `${actionName}_ERROR`,
  actionName,
});

export const createPaginationActionSet = actionName => ({
  ...createActionSet(actionName),
  RESET: `${actionName}_RESET`,
});

```


```js
//auth.type.js

import { createActionSet } from 'utils';

export const CHANGE_LOCALE = createActionSet('CHANGE_LOCALE');
export const GET_AUTH_ORGS = createActionSet('GET_AUTH_ORGS');
export const GET_AUTH_STAR_COUNT = createActionSet('GET_AUTH_STAR_COUNT');
export const GET_AUTH_USER = createActionSet('GET_AUTH_USER');
export const LOGIN = createActionSet('LOGIN');
export const LOGOUT = createActionSet('LOGOUT');

```


由于异步操作开销比较大，所以对于已经执行过的流程，可以缓存起来，GitPoint使用了`reselect`库来执行这个操作

```js
import { createSelector } from 'reselect';

export const getAuthFromStore = state => state.auth;
//缓存了用户的认证信息和当前的地理位置
export const getAuthLocale = createSelector(
  getAuthFromStore,
  auth => auth.locale
);

```


具体执行state修改的是reducer文件.
首先从`auth.type.js`中加载 actionType,目的是要和组件dispacth的 actionType做匹配，决定要执行那个修改state的操作

`初始State`

```js
export const initialState = {
  isLoggingIn: false,
  isSigningOut: false,
  isAuthenticated: false,
  accessToken: null,
  user: {},
  hasInitialUser: false,
  orgs: [],
  events: [],
  // TODO: there should not be a dependency here that can't be constructor injected.
  locale: getLocale(),
  isPendingUser: false,
  isPendingOrgs: false,
  isPendingEvents: false,
  error: '',
};

```


根据actionType对state做出操作(Immutable)

```js
//auth.reducer.js

export const authReducer = (state = initialState, action = {}) => {
  switch (action.type) {
    case LOGIN.PENDING:
      return {
        ...state,
        isLoggingIn: true,
        isAuthenticated: false,
      };
    case LOGIN.SUCCESS:
      return {
        ...state,
        isLoggingIn: false,
        isAuthenticated: true,
        accessToken: action.payload,
      };
    case LOGIN.ERROR:
      return {
        ...state,
        isLoggingIn: false,
        isAuthenticated: false,
        error: action.payload,
      };
    case LOGOUT.PENDING:
      return {
        ...state,
        isSigningOut: true,
      };
    case LOGOUT.SUCCESS:
      return {
        ...initialState,
        hasInitialUser: false,
      };
    case LOGOUT.ERROR:
      return {
        ...state,
        isSigningOut: false,
        error: action.payload,
      };
    case GET_AUTH_USER.PENDING:
      return {
        ...state,
        isPendingUser: true,
      };
    case GET_AUTH_USER.SUCCESS:
      return {
        ...state,
        isPendingUser: false,
        hasInitialUser: true,
        user: action.payload,
      };
    case GET_AUTH_USER.ERROR:
      return {
        ...state,
        isPendingUser: false,
        error: action.payload,
      };
    case GET_AUTH_STAR_COUNT.PENDING:
      return {
        ...state,
        isPendingStarCount: true,
      };
    case GET_AUTH_STAR_COUNT.SUCCESS:
      return {
        ...state,
        isPendingStarCount: false,
        starCount: action.payload,
      };
    case GET_AUTH_STAR_COUNT.ERROR:
      return {
        ...state,
        isPendingStarCount: false,
        error: action.payload,
      };
    case GET_AUTH_ORGS.PENDING:
      return {
        ...state,
        isPendingOrgs: true,
      };
    case GET_AUTH_ORGS.SUCCESS:
      return {
        ...state,
        isPendingOrgs: false,
        orgs: action.payload,
      };
    case GET_AUTH_ORGS.ERROR:
      return {
        ...state,
        isPendingOrgs: false,
        error: action.payload,
      };
    case CHANGE_LOCALE.SUCCESS:
      return {
        ...state,
        locale: action.payload,
      };
    default:
      return state;
  }
};

```




















