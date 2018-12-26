---
title: GraphQL Playground 列表
date: 2018-01-21 13:55:28
categories: 翻译
tags: [Github,graphql]
---
     #GraphQL  playground  
  [`graphql-api地址`](https://github.com/APIs-guru/graphql-apis)    
  
  ### Gdom
 通过grphql爬取dom元素
 
 <iframe src="http://gdom.graphene-python.org/graphql?query=%7B%0A++page%28url%3A%22http%3A%2F%2Fnews.ycombinator.com%22%29+%7B%0A++++items%3A+query%28selector%3A%22tr.athing%22%29+%7B%0A++++++rank%3A+text%28selector%3A%22td+span.rank%22%29%0A++++++title%3A+text%28selector%3A%22td.title+a%22%29%0A++++++sitebit%3A+text%28selector%3A%22span.comhead+a%22%29%0A++++++url%3A+attr%28selector%3A%22td.title+a%22%2C+name%3A%22href%22%29%0A++++++attrs%3A+next+%7B%0A+++++++++score%3A+text%28selector%3A%22span.score%22%29%0A+++++++++user%3A+text%28selector%3A%22a%3Aeq%280%29%22%29%0A+++++++++comments%3A+text%28selector%3A%22a%3Aeq%282%29%22%29%0A++++++%7D%0A++++%7D%0A++%7D%0A%7D" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allrow-popups allow-scripts allow-same-origin">
</iframe>

### Mongodb_todo demo  
todo
<iframe src="https://todo-mongo-graphql-server.herokuapp.com" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allrow-popups allow-scripts allow-same-origin">
</iframe>

###  更据查询要求来绘图
<iframe src="https://jwerle.github.io/three.graphql/" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allrow-popups allow-scripts allow-same-origin">
</iframe>

### 电影数据库查询


<iframe src="https://etmdb.com/graphql?query=%7B%0A%20%20allCinemaDetails(before%3A%20%222017-10-04%22%2C%20after%3A%20%222010-01-01%22)%20%7B%0A%20%20%20%20edges%20%7B%0A%20%20%20%20%20%20node%20%7B%0A%20%20%20%20%20%20%20%20slug%0A%20%20%20%20%20%20%20%20hallName%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D%0A" style="width:100%; height:500px; border:0; border-radius: 4px; overflow:hidden;" sandbox="allow-modals allow-forms allrow-popups allow-scripts allow-same-origin">
</iframe>





