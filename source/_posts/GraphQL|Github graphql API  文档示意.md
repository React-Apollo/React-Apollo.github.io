---
title: GraphQL|Github graphql API  文档示意
date:  2018-03-09 10:52:29
categories: 技术备忘
tags: [GraphQL,API, Github]
---

> 克隆 gitpoint 的项目 ,记录一下 GraphQL 的查询,就可以作为文档了. 按照 gitpoint 的 tab顺序来. 项目初衷, gitpoint 用的是 Redux,写的很好,功能也很完备,Redux的一个优点是单一数据来源.但是如果是远程数据, REST API 提供的数据, 却并不是单一来源的,而且每个远程请求的状态都要自己配置. 代码量太大. 使用 GraphQL的服务, 真正做到了单一数据来源, 把多个数据接口变为一个接口. 返回数据可以灵活安排, 代码减少了很多. 

## 1.Profile 查询

### 1.1 profile.screen 数据查询
viewer 查询当前登录用户的信息

```
	query  viewer{
	   viewer{
	      
	      login
	      email
	      bio
	      name
	      avatarUrl
	      location
	      repositories{
	        totalCount
	      }
	      repositoriesContributedTo{
	         totalCount
	       }
	      followers{
	        totalCount
	      }
	      following{
	        totalCount
	      }
	    
	      organizations(first:5){
	        edges{
	          node{
	            name
	            avatarUrl
	            teams(first:5){
	              edges{
	                node{
	                  name
	                  avatarUrl
	                  
	                }
	              }
	            }
	          }
	        }
	      }
	    
	  }
	}
  

```

结果 一次查询出 profile 页面的所有数据

```
{
  "data": {
    "viewer": {
      "repositoriesContributedTo": {
        "totalCount": 6
      },
      "login": "phpsmarter",
      "email": "3238355967@qq.com",
      "bio": "A React Native code beginner",
      "name": "phpsmarter",
      "avatarUrl": "https://avatars3.githubusercontent.com/u/10001670?v=4",
      "location": null,
      "repositories": {
        "totalCount": 486
      },
      "followers": {
        "totalCount": 5
      },
      "following": {
        "totalCount": 0
      },
      "organizations": {
        "edges": [
          {
            "node": {
              "name": "edulamp",
              "avatarUrl": "https://avatars2.githubusercontent.com/u/10001682?v=4",
              "teams": {
                "edges": [
                  {
                    "node": {
                      "name": "Owners",
                      "avatarUrl": "https://avatars2.githubusercontent.com/t/1156109?s=400&v=4"
                    }
                  }
                ]
              }
            }
          }
        ]
      }
    }
  }
}
```

### 1.2  查询粉丝

```
query FollowerList {
  user(login: "phpsmarter") {
    followers(first: 10) {
      edges {
        node {
          name
          avatarUrl
          email
        }
      }
    }
  }
}
```

结果

```
{
  "data": {
    "user": {
      "followers": {
        "edges": [
          {
            "node": {
              "name": "liujian zhang",
              "avatarUrl": "https://avatars2.githubusercontent.com/u/4494312?v=4",
              "email": "ziaochina@gmail.com"
            }
          },
          {
            "node": {
              "name": "Ömer DOĞAN",
              "avatarUrl": "https://avatars2.githubusercontent.com/u/6252528?v=4",
              "email": "omer_dogan@outlook.com"
            }
          },
          {
            "node": {
              "name": "Archakov Dennis",
              "avatarUrl": "https://avatars3.githubusercontent.com/u/12086860?v=4",
              "email": "hello@archakov.im"
            }
          },
          {
            "node": {
              "name": "Prachi Sharma",
              "avatarUrl": "https://avatars0.githubusercontent.com/u/13256500?v=4",
              "email": "prachi.asm@gmail.com"
            }
          },
          {
            "node": {
              "name": null,
              "avatarUrl": "https://avatars0.githubusercontent.com/u/21312042?v=4",
              "email": ""
            }
          }
        ]
      }
    }
  }
}
```


====================================================================

## 2. Repo的查询
### 2.1 repoList的查询

### 2.2 repo的查询

```
query repo($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    name
    url
    stargazers {
      totalCount
    }
    owner {
      avatarUrl
      login
    }
    collaborators(first: 20) {
      edges {
        node {
          avatarUrl
          name
          url
        }
      }
    }
    pullRequests {
      totalCount
    }
    createdAt
    description
    forkCount
  }
}

```

结果是

```
{
  "data": {
    "repository": {
      "name": "react-native-lagou",
      "url": "https://github.com/phpsmarter/react-native-lagou",
      "stargazers": {
        "totalCount": 1
      },
      "owner": {
        "avatarUrl": "https://avatars3.githubusercontent.com/u/10001670?v=4",
        "login": "phpsmarter"
      },
      "collaborators": {
        "edges": [
          {
            "node": {
              "avatarUrl": "https://avatars3.githubusercontent.com/u/10001670?v=4",
              "name": "phpsmarter",
              "url": "https://github.com/phpsmarter"
            }
          }
        ]
      },
      "pullRequests": {
        "totalCount": 0
      },
      "createdAt": "2016-02-18T10:18:18Z",
      "description": "用react native写的仿拉勾ios版本demo",
      "forkCount": 0
    }
  }
}
```


