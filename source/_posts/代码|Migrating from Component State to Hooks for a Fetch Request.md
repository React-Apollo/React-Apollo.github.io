---
title:  代码|Migrating from Component State to Hooks for a Fetch Request
date: 2019-4-19 21:39
categories: 技术备忘
tags: [React-Native,React-Hooks,Fetch,StarWar]
---
[Migrating from Component State to Hooks for a Fetch Request](https://www.reactnativeschool.com/migrating-from-component-state-to-hooks-for-a-fetch-request)

> React-Hooks的用法, 包装Hooks,然后返回一组接口, 这是React-Hooks提倡的用法
{{TOC}}

`原始代码`
```javascript
import React from 'react';
import {
  StyleSheet,
  Text,
  View,
  FlatList,
  SafeAreaView,
  ActivityIndicator,
  Button,
} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default class App extends React.Component {
  state = {
    people: [],
    loading: true,
    page: 1,
  };

  componentDidMount() {
    this.getPeople();
  }

  getPeople = () => {
    this.setState({ loading: true });
    fetch(`https://swapi.co/api/people?page=${this.state.page}`)
      .then(res => res.json())
      .then(res => {
        this.setState(state => ({
          people: [...state.people, ...res.results],
          loading: false,
        }));
      });
  };

  render() {
    return (
      <SafeAreaView style={{ flex: 1 }}>
        <FlatList
          data={this.state.people}
          keyExtractor={item => item.url}
          renderItem={({ item }) => (
            <View>
              <Text>{item.name}</Text>
            </View>
          )}
          ListFooterComponent={
            this.state.loading ? (
              <ActivityIndicator />
            ) : (
              <Button
                title="Load More"
                onPress={() => {
                  this.setState(
                    state => ({ page: state.page + 1 }),
                    this.getPeople
                  );
                }}
              />
            )
          }
        />
      </SafeAreaView>
    );
  }
}
```



`React-Hooks包装的代码`

```javascript
const useSwapiPeople = () => {
  const [people, setPeople] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);

  useEffect(
    () => {
      setLoading(true);
      fetch(`https://swapi.co/api/people?page=${page}`)
        .then(res => res.json())
        .then(res => {
          setPeople([...people, ...res.results]);
          setLoading(false);
        });
    },
    [page]
  );

  const loadMore = () => {
    setPage(page + 1);
  };

  return {
    people,
    loading,
    loadMore,
  };
};

export default () => {
  const { people, loading, loadMore } = useSwapiPeople();

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <FlatList
        data={people}
        keyExtractor={item => item.url}
        renderItem={({ item }) => (
          <View>
            <Text>{item.name}</Text>
          </View>
        )}
        ListFooterComponent={
          loading ? (
            <ActivityIndicator />
          ) : (
            <Button title="Load More" onPress={loadMore} />
          )
        }
      />
    </SafeAreaView>
  );
};
```


`‌核心部分`

组件需要三个state,1️⃣是从API返回的数据,2️⃣是远程异步操作的提示状态,3️⃣是分页状态. 

作者这里的代码进行了重构, 返回了数据和加载提示, 分页标识外部不可见,只暴露了函数.  

```javascript
const useSwapiPeople = () => {
  const [people, setPeople] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);

  useEffect(
    () => {
      setLoading(true);
      fetch(`https://swapi.co/api/people?page=${page}`)
        .then(res => res.json())
        .then(res => {
          setPeople([...people, ...res.results]);
          setLoading(false);
        });
    },
    [page]
  );

  const loadMore = () => {
    setPage(page + 1);
  };

  return {
    people,
    loading,
    loadMore,
  };
};

```