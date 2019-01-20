---
title: 翻译|18 Tips for Training your own Tensorflow.js Models in the Browser
date: Thursday, December 13, 2018 at 12:47:03 PM China Standard Time
categories: Medium
tags: [TensorFlow.js, Machine Learning, JavaScript]
---

[`参见原文`](https://itnext.io/18-tips-for-training-your-own-tensorflow-js-models-in-the-browser-3e40141c9091)

在导入已有的用于物体检测,面部检测,面部识别模型之后,what not to tensorflow.js之后.我发现有些模型性能不太好了,但是有些模型在浏览器端性能很好. 如果你认真思考了浏览器端的机器学习模型的潜能,以及所有可以使用库,你可能会觉得很神奇.

然而, 直接在浏览器端运行深度模型,我们也面临着存在模型的一些局限,这些模型设计之初并不是用于客户端的,移动浏览器就更不要想了. 就拿物体检测作为实例:通常都需要大量的计算资源确保模型的流畅运行,保持实时的速度. 此外,在浏览器端加载100MB+ 的权重参数也不太可行.

## 为 web 环境训练有效的深度学习模型

但是,希望最终会实现. 我要告诉你,如果考虑一些基本的原则,我们也能够训练处相当地道的模型,专门用于web环境.信不信由你:我们可以训练出真正的图片分类,甚至是物体检测模型,最终大小之后几兆,甚至是几十kb. 

