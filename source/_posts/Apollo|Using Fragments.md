---
title: Apollo|Using Fragments
date: 2018-03-27 10:39:30
categories: 技术备忘
tags: [Apollo,graphql]
---

> `GraphQL fragments`是可以共享的查询逻辑

```js
fragment NameParts on Person {
  firstName
  lastName
}

query getPerson {
  people(id: "7") {
    ...NameParts
    avatar(size: LARGE)
  }
}
```

在 Apollo中 fragment 有两个主要的用法:
- 在多个查询,突变或订阅中共享字段
- Breaking your queries up to allow you to co-locate field access with the places they are used.

## Reusing Fragments
直接的用法就是重用片段

```
import gql from 'graphql-tag';

CommentsPage.fragments = {
  comment: gql`
    fragment CommentsPageComment on Comment {
      id
      postedBy {
        login
        html_url
      }
      createdAt
      content
    }
  `,
};
```

需要使用 fragment 时, 简单的使用`...Name`语法. 在查询文档中嵌入

```js
const SUBMIT_COMMENT_MUTATION = gql`
  mutation submitComment($repoFullName: String!, $commentContent: String!) {
    submitComment(repoFullName: $repoFullName, commentContent: $commentContent) {
      ...CommentsPageComment
    }
  }
  ${CommentsPage.fragments.comment}
`;

export const COMMENT_QUERY = gql`
  query Comment($repoName: String!) {
    # ...
    entry(repoFullName: $repoName) {
      # ...
      comments {
        ...CommentsPageComment
      }
      # ...
    }
  }
  ${CommentsPage.fragments.comment}
`;
```

## Colocating Fragments

GraphQL的一个好处是, 响应数据天然是树形结构,在很多实例中, 和组件的层级关系形成映射.由此,结合GraphQL对 fragment 的支持,可以按照对应结构对查询做出分割.

例如在GitHunt 中构建`FeedPage`实例,有如下的层级结构

```js
FeedPage
└── Feed
    └── FeedEntry
        ├── RepoInfo
        └── VoteButtons
```

`FeedPage` 执行一个查询获取`Entry`列表.每个子组件需要`Entry`的不同字段.

`graphql-anywhere`包提供的工具可以构建出子组件需要的所有字段的查询,从而让你轻松的传递所有组件需要确切字段

## Creating Fragments
再次使用`gql`助手,添加子字段

```
VoteButtons.fragments = {
  entry: gql`
    fragment VoteButtons on Entry {
      score
      vote {
        vote_value
      }
    }
  `,
};
```

如果片段包含有子片段, 使用`gql`助手传递

```js
FeedEntry.fragments = {
  entry: gql`
    fragment FeedEntry on Entry {
      commentCount
      repository {
        full_name
        html_url
        owner {
          avatar_url
        }
      }
      ...VoteButtons
      ...RepoInfo
    }
    ${VoteButtons.fragments.entry}
    ${RepoInfo.fragments.entry}
  `,
};
```

## Filtering With Fragments

在字段传递给子组件的时候,也可是过滤出确切的字段

```js
import { filter } from 'graphql-anywhere';

<VoteButtons
  entry={filter(VoteButtons.fragments.entry, entry)}
  canVote={loggedIn}
  onVote={type => onVote({
    repoFullName: full_name,
    type,
  })}
/>
```

`filter()`会从 `entry`中得到确切的字段

## 使用 Webpack 导入 fragments
在使用`graphql-tag/loader`导入`.graphql`文件时,可以使用`import`,

```js
#import "./someFragments.graphql"
```

