---
title: Apollo-client 的Incremental loading(增量加载)
date: 2018-02-04 13:22:27
categories: 技术备忘
tags: [Graphql,apollo]
---

{{TOC}}

## Incremental loading
### `fetchmore`方法

```js
const FeedQuery = gql`
  query Feed($type: FeedType!, $offset: Int, $limit: Int) {
    # ...
  }`;

const FeedWithData = graphql(FeedQuery, {
  props({ data: { loading, feed, currentUser, fetchMore } }) {
    return {
      loading,
      feed,
      currentUser,
      loadNextPage() {
        return fetchMore({
          variables: {
            offset: feed.length,
          },

          updateQuery: (previousResult, { fetchMoreResult }) => {
            if (!fetchMoreResult) { return previousResult; }

            return Object.assign({}, previousResult, {
              feed: [...previousResult.feed, ...fetchMoreResult.feed],
            });
          },
        });
      },
    };
  },
})(Feed);
```
执行查询任务的时候, props里会有一个length属性, 可以作为无限加载的一个偏移标记,比如在 cnode 的查询 REST中,如果下一页page+1,就可以用这个 length+1来作为下一个加载的查询参数
```
 page=length+1
```



