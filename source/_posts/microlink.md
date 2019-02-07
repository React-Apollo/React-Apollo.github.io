---
title: MicroLink使用
date: 2019-02-07 10:24
categories: 技术备忘
tags: [React,Styled-Component]
---


{{TOC}}

 # MicroLink使用

## 安装

```bash
$ npm install @microlink/react styled-components --save
```
## 使用方法

```jsx
import MicrolinkCard from '@microlink/react'

// Just provide a URL to create a card
<MicrolinkCard
  url='https://www.theverge.com/tldr/2018/2/7/16984284/tesla-space-falcon-heavy-launch-elon-musk'
/>

//size:'large'
```

##  Styling
- microlink_card: 是根 `div`
- micro_card_media: 可以是`video`或者`image`
- mircolink_card_media_image : `div`用于包装link的preview的background-image
- microlink_card_media_video_wrapper:  video link 的preview包装器
- microlink_card_media_video :link video preview 的`video`元素
- micro_card_content: link content 的 `div`
- micro_card_content: link content
- microlink_card_content_title:  card title  `p`元素
- microlink_card_content_description: card description
- microlink_card_content_url:  link url  `span`元素




## 使用styled-components进行修饰

```jsx
import MicrolinkCard from '@microlink/react'
import styled from 'styled-components'

const myCustomCard = styled(MicrolinkCard)`
  font-family: 'Nitti, "Microsoft YaHei", 微软雅黑, monospace';
  max-width: 100%;
  border-radius: .42857em;
`
```

> `设想是通过爬虫抓取url,然后生成pocket形式的网页`

