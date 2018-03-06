---
title: Apollo|Recompose Pattern
date: 2018-03-06 07:29:33
categories: 技术备忘
tags: [GraphQL,Apollo]
---
{{TOC}}
# Recompose patterns

## 1. `Loading status`
常规做法: 根据 data.loading来显示 Loading 组件

```js
const Component = props => {
  if (props.data.loading) {
    return <LoadingPlaceholder>
  }

  return (
    <div>Our component</div>
  )
}
```

 Recompose 有一个工具函数`branch()`,可以基于其中检测函数(test)的结果来组合不同的 Hoc, 可以和另一个 Recompose方法`renderComponent()`,联合使用.所以可以说:"如果处于 loading 状态, 就渲染`LoadingPlaceholder`而不是默认要展示内容的组件",实例如下:
 
 `Recompose loading`
 
```
 import { propType } from 'graphql-anywhere'
//props.data.loading为真时就渲染传入的组件,这里是LoadingPlaceholder
const renderWhileLoading = (component, propName = 'data') =>
  branch(
    props => props[propName] && props[propName].loading,
    renderComponent(component),
  );
// 这个组件是实际展示数据的组件
const Component = props => (<div>Our component for {props.user.name}</div>)
Component.propTypes = {
  user: propType(getUser).isRequired, // autogenerating proptypes, as we expect them to be always there (yeah, if no error)
}
//如果 graphql 的状态是 data.loading, renderWhileLoading 会劫持渲染
const enhancedComponent = compose(
  graphql(getUser, { name: "user" }),
  renderWhileLoading(LoadingPlaceholder, "user")
)(Component);

export default enhancedComponent;
```


> **注意事项:** `Loading`只有才查询的第一次才会为真. 如果使用`options.notifyOnNetworkStatusChange`,可以用`data.networkStatus`字段来跟踪其他的 loading 状态.模式和上面的一样


## 2.  `处理错误`

和 loadingStatus 的方法类似,如果出了问题,我们想显示一个不同的组件,或者允许用户重新加载(`refetch()`). 使用`withProps()`方法直接用 props 传递 refetch 方法.  这里的方法是通用的, 没有和任何的组件耦合.

```js
const renderForError = (component, propName = "data") =>
  branch(
    props => props[propName] && props[propName].error,
    renderComponent(component),
  );

const ErrorComponent = props =>(
  <span>
    Something went wrong, you can try to
    //⛔️ props 传入的 refetch 方法
    <button onClick={props.refetch}>refetch</button>
  </span>
)
//为组件注入新的props 和 refetch 方法
const setRefetchProp = (propName = "data") =>
  withProps(props => ({refetch: props[propName] && props[propName].data}))

const enhancedComponent = compose(
  graphql(getUser, { name: "user" }),
  renderWhileLoading(LoadingPlaceholder, "user"),
  setRefetchProp("user"),
  renderForError(ErrorComponent, "user"),
)(Component);

export default enhancedComponent;
```


## 3.  `查询周期`

在有些用例中,需要在查询完成之后执行一些其他工作. 上面的实例中,没有错误出现,没有 loading 的时候会渲染默认组件.

但是组件是无状态的,没有生命周期函数的钩子(hook).如果还要使用额外的周期功能,可以用 Recompose 的`lifecycle()`函数来补救

```js
const execAtMount = lifecycle({
  componentWillMount() {
    executeSomething();
  },
})

const enhancedComponent = compose(
  graphql(getUser, { name: "user" }),
  renderWhileLoading(LoadingPlaceholder, "user"),
  setRefetchProp("user"),
  renderForError(ErrorComponent, "user"),
  execAtMount,
)(Component);
```

上面的实例,如果我们需要在组件加载时做些额外的工作,可以这么操作

   来看看另一个更为复杂的用例, 例如我正在使用`re-select`,可以让用户从查询的结果中挑选部分内容. 想一直显示 re-select,它有自己的 loading state indicator.接着在查询成功以后自动的选择预定义的选项.
   如果使用默认的访问策略(fetchPolicy)让每个组件都获取数据,只有一个特别的地方需要处理. 需要留意的地方:`要查询的数据已经在 cache 中的时候,就会跳过 loading state`. 这种情况下,我们需要在组件加载时处理`networkStatus===7`.
   同时还要使用recompose的`withState()`方法保存选项值. 在这个例子中我们保持默认的`data`属性不变.
   
```
const DEFAULT_PICK = "orange";
const withPickerValue = withState("pickerValue", "setPickerValue", null);

// find matching option
const findOption = (options, ourLabel) =>
  lodashFind(options, option => option.label.toLowerCase() === ourLabel.toLowerCase());

const withAutoPicking = lifecycle({
  componentWillReceiveProps(nextProps) {
    // when value was already picked
    if (nextProps.pickerValue) {
      return;
    }
    // networkStatus change from 1 to 7 - initial load finished successfully
    if (this.props.data.networkStatus === 1 && nextProps.data.networkStatus === 7) {
      const match = findOption(nextProps.data.options)
      if (match) {
        nextProps.setPickerValue(match);
      }
    }
  },
  componentWillMount() {
    const { pickerValue, setPickerValue, data } = this.props;
    if (pickerValue) {
      return;
    }
    // when Apollo query is resolved from cache,
    // it already have networkStatus 7 at mount time
    if (data.networkStatus === 7 && !data.error) {
      const match = findOption(data.options);
      if (match) {
        setPickerValue(match);
      }
    }
  },
});

const Component = props => (
  <Select
    loading={props.data.loading}
    value={props.pickerValue && props.pickerValue.value || null}
    onChange={props.setPickerValue}
    options={props.data.options || undefined}
  />
);

const enhancedComponent = compose(
  graphql(getOptions),
  withPickerValue,
  withAutoPicking,
)(Component);
```
   
   

## 4. `控制轮询`
>这个例子是一个显示 meteor框架中的数据库迁移状态的组件:migrations panel.并不总是运行迁移,所以设置轮询为30s,就比较好.但是如果在数据库迁移过程中,我们需要竟可能快的显示进度.

> 解决问题的关键是 react-apollo 的`options`参数, 这个参数可以是一个依赖于 React props 为参数的函数.(`options`参数描述了查询自身的参数, 和 React 的 props 是不同的). 我们可以根据传递到graphql 组件的 props,通过使用recompose的`withState()`函数设定轮询的周期,并且使用`componentWillReceiveProps` React的生命周期函数来查看从 GraphQL获取的数据,并作出相应的调整. 

> 基本的流程就是,默认30秒查询一次数据库迁移状态的数据,如果数据存在时,就立刻把查询的轮询时间改为0.5s.


代码如下:

```
import { graphql } from "react-apollo";
import gql from "graphql-tag";
import { compose, withState, lifecycle } from "recompose";

const DEFAULT_INTERVAL = 30 * 1000;
const ACTIVE_INTERVAL = 500;

const withData = compose(
  // Pass down two props to the nested component: `pollInterval`,
  // which defaults to our normal slow poll, and `setPollInterval`,
  // which lets the nested components modify `pollInterval`.
  withState("pollInterval", "setPollInterval", DEFAULT_INTERVAL),
  graphql(
    gql`
      query getMigrationStatus {
        activeMigration {
          name
          version
          progress
        }
      }
    `,
    {
      // If you think it's clear enough, you can abbreviate this as:
      //   options: ({pollInterval}) => ({pollInterval}),
      options: props => {
        return {
          pollInterval: props.pollInterval
        };
      }
    }
  ),
  lifecycle({
    componentWillReceiveProps({
      data: { loading, activeMigration },
      pollInterval,
      setPollInterval
    }) {
      if (loading) {
        return;
      }
      if (activeMigration && pollInterval !== ACTIVE_INTERVAL) {
        setPollInterval(ACTIVE_INTERVAL);
      } else if (
        !activeMigration &&
        pollInterval !== DEFAULT_INTERVAL
      ) {
        setPollInterval(DEFAULT_INTERVAL);
      }
    }
  })
);
const MigrationPanelWithData = withData(MigrationPanel);
```


但是这个轮询似乎还有缺陷, 如果在30s轮询周期内, 数据库迁移完成了,我们就看不到任何的提示. 或许要使用 subscription方法. 
 
 



