---
title: 翻译|face-api.js — JavaScript API for Face Recognition in the Browser with tensorflow.js
date: Thursday, December 13, 2018 at 9:19:49 AM China Standard Time
categories: 技术备忘
tags: [JavaScript,Medium,TensorFlow.js]
---



# face-api.js — JavaScript API for Face Recognition in the Browser with tensorflow.js


[`原文在此`](https://itnext.io/face-api-js-javascript-api-for-face-recognition-in-the-browser-with-tensorflow-js-bcc2a6c4cf07)

![](https://ws3.sinaimg.cn/large/006tNbRwly1fy4uvcp0qij30gr0a1781.jpg)


我很高兴的说,在浏览器端运行人脸识别程序终于可以实现了! 在本文我会结合介绍一个 JavaScript模块,也就是 [`face-api.js`](https://github.com/justadudewhohacks/face-api.js), 本模块基于[`tensroflow.js 核心`](https://github.com/tensorflow/tfjs-core)构建,tensorflow.js的核心实现了几种 CNN(Convolutional Neural network,卷积神经网络),可以用来接解决面部检测,面部识别和面部标记检测任务, 并且对 web 端和移动端做了特别的优化.

因为我们总是想要找简单的代码示例,简单代码可以使用软件包,用几行代码就可以立刻开始项目.如果你想先试试一些示例,看看 [`Demo页`](https://justadudewhohacks.github.io/face-api.js/)!但是不要忘了回来读文章啊. ;)

开始吧!

注意:文章中的项目还在继续开发中.需要你保证检查一下文章的更新情况,保证获取到最新的face-api.js的特征:

- [Realtime JavaScript Face Tracking and Face Recoginition using face-api.js'MTCNN Face Detector](https://itnext.io/realtime-javascript-face-tracking-and-face-recognition-using-face-api-js-mtcnn-face-detector-d924dd8b5740)


## 为什么开始时face-recognition.js,现在是另外一个软件包?

如果以读过我的另外一篇文章,使用node.js的面部识别的文章: [ Node.js + face-recognition.js : Simple and Robust Face Recognition using Deep Learning](https://medium.com/@muehler.v/node-js-face-recognition-js-simple-and-robust-face-recognition-using-deep-learning-ea5ba8e852),你可能知道,不久以前,我发布了一个类似的软件包,就是 [face-recognition.js](https://github.com/justadudewhohacks/face-recognition.js),可以用node.js实现面部识别.

刚开始,我没有想到 Javascript 社区对于面部识别有这么高的要求.对于很多程序员,face-recognition.js似乎是很严肃的取代了付费的产品,例如微软h和亚马逊的产品. 但是也有很多还想更进一步,看看是否有直接在浏览器端运行的面部识别流程.

那么,最终这个软件包就出现了,完全要感谢tensorflow.js! 使用tfjs-core,我成功的实现了部分相似的功能,使用新的软件包可以得到和face-recoginiton.js 同样的结果,但是是运行在浏览器端的!还有,face-api.js提供的模型专门对 web 进行了优化,以便于在移动设备上运行资源,face-api.js是开箱即用的.有点是它是 GPU加速的,操作运行是以 WebGL最为后台的.

这些原因很充分,是我确信 javascript 社区需要浏览器端的包!剩下的就是你的想象力, 可以用这个软件包构建各种应用了.;)

## 怎么使用深度学习来解决面部识别问题?

如果是急性子的人, 想要马上看到结果, 可以直接跳过这一小节,直接去看代码. 但是为了更好的理解face-api.js在面部识别方面的实现原理,我还是强烈建议你继续往下读.因为我经常被请求讲解其中的原理.

为了讲解简单一点,我们实际是想从某人的给定图像例如,输入的图片来识别一个人.方法是提供我们想识别人的一张或者多张图片,并且使用姓名标记,作为参考数据.现在我们可以比较输入图片和参考数据,找到和参考数据图片最相似的图片.如果两张图片相似度足够高,我们就输入是需要识别人的姓名, 否则就输入 `未知`.

听起来是个完美的计划!但是还有两个问题要解决. 第一个,如果过我们有一张多人的图片,想识别其中每个人,怎么办? 第二个,我们想要获取两张面部照片的相似度,以便于可以对他们进行比较...

### 面部识别

第一个问题的答案是面部检测.简单讲,我们首先定位出输入图片中的所有面部.Fact-api.js实现了用于多面部检测用于不同的用例.

最准确的面部检测器是 SSD(Single Shot Multibox Detector),它的基础是基于 CNN 的 MobileNet V1,它在基础的卷积神经网络上构建了额外的预测层.

此外, face-api.js实现了经过优化的 `Tiny Face Detector`, 基本上是一个Tiny Yolo V2的更小的版本. Tiny Yolo是一个深度分离卷积网络而不是常规的卷积, 深度分离卷积的速度更快,但是和 SSD  MobileNet V1相比精确度稍差一点.

最后,也就是 MTCNN(Mutli-task Cascaded Convolutional Neural Network)的实现, 然而,现在它用于实验性质多一点.

这些网络返回每张脸的`边界盒子(bouding boxes)`,还有对应的得分,例如,每个盒子显示为面部的概率.得分用于对边界盒子进行过滤.一张图片中完全没有人脸出现也是有可能的.注意,为了获得边界盒子,即使没有图片中没有人,也要执行面部检测.

![](https://ws2.sinaimg.cn/large/006tNbRwly1fy4wd4lbumj30go0auadb.jpg)

### 面部标志检测和面部对齐

第一个问题解决了.但是我想指出,我们想对齐边界盒子,在把每个盒子传递给面部识别网络之前,我们想让面部位于提取图片的中央, 这样的操作会使面部识别的精确度更高.

face-api.js的对策是实现了一个简单的 CNN,返回给定脸部图像的68个标志点:

![](https://ws4.sinaimg.cn/large/006tNbRwly1fy4wib3dhlj308e0450te.jpg)


根据标志点的位置,分解盒子可以被集中到脸部的中央. 下面你可以看到脸部检测结果(左图)和经过对齐的脸部图片(右图)的比较.

![](https://ws2.sinaimg.cn/large/006tNbRwly1fy4wkqv1cuj30hm0303zd.jpg)


## 面部识别

现在,我们把经过对齐的图片输入到面部识别网络,面部识别网络是基于 与`ReSNet-34`相似的构架,基础构架实现在[`dlib`](https://github.com/davisking/dlib/blob/master/examples/dnn_face_recognition_ex.cpp) . 识别网络训练的任务是人脸的特征映射到面部描述(有128个值的特征向量),这个任务通常也称为面部嵌入.

现在返回初始的问题,就是两张脸的对比: 我们把从每张面部图片提取的特征向量描述向量和参考数据的特征向量进行比较. 说的更准确一点,就是比较两张量的特征向量之间的欧几里得距离(euclidean distance,译注:简单的几何,两点之间的距离计算).基于一个阈值(对于150X150大小的图片,0.6是一个比较好的阈值)来进行判断. 欧氏距离的工作出奇的好,当然你可以根据喜好选择其他的分类器.下面的图是比较两张脸的欧式距离:

![](https://ws1.sinaimg.cn/large/006tNbRwly1fy4wylr1n1j30c80azaay.jpg)


![](https://ws2.sinaimg.cn/large/006tNbRwly1fy4wymwxv2j30c60al0tl.jpg)


现在我们已经详细了解了面部识别的理论, 开始来编码一个示例程序

## 具体代码

在这一部分,我们会一步一步实现一个面部识别程序,显示出下面图片中的每个人

![](https://ws4.sinaimg.cn/large/006tNbRwly1fy4x1lrperj30go09hjup.jpg)

### 引入脚本

首先,从dist/face-api.js得到最新的版本,或者是压缩的版本 /dist/face-api.min.js:

```javascript
<script src="face-api.js"></script>

```

也可以使用npm安装

```bash
npm i face-api.js
```

### 加载模型数据
根据应用的需求不同,你可以加载特定的模型,但是从头至尾运行本实例,需要加载面部检测,面部标记和面部识别模型. 模型文件仓库在[`这里`](https://github.com/justadudewhohacks/face-api.js/tree/master/weights)

模型权重已经被quantized,和原始的模型相比大小已经缩减了75%,由此客户端可以只加载必须的数据. 此外, 模型的权重被分外4MB 大小的块,浏览器可以缓存这些文件,不需要再加载第二次.

模型文件也可以通过web app的静态资源提供,或者可以放在任何定义的路由或者 ulr下. 假设你已经在public/models下提供了模型目录:


```javascript
const MODEL_URL = '/models'

await faceapi.loadSsdMobilenetv1Model(MODEL_URL)
await faceapi.loadFaceLandmarkModel(MODEL_URL)
await faceapi.loadFaceRecognitionModel(MODEL_URL)
```


### 从输入图片获取所有脸部的完整描述

神经网络接收 HTML图片,canvas,或者是视频元素,或者是图片的tensors作为输入. 为了检测输入图片中的所有边界盒子,代码如下:

```javascript
const input=document.getElementById('myImage');
let fullFaceDescriptions = await faceapi.detectAllFaces(input).withFaceLandmarks().withFaceDescriptors()
```

完整的面部描述包含了探测的结果(边界盒子+得分),面部标记也作为描述的计算结果. 省略 *faceapi.detectAllFaces(input,options)* 可选参数,我们就默认使用 SSD MobileNet V1作为默认的模型.如果要使用Tiny Face检测或者是 MTCNN 方法,只需要定义对应的选项就可以了.

有关face detection 选项的细节,可以看看 github仓库的说明文档.注意,必须要提前记载相应的模型,.

返回的边界盒子和标记位置是对应于原始的图片/媒体尺寸的. 万一显示的图片和原始的图片大小不对应,需要 resize:

```javascript
fullFaceDescriptions = fullFaceDescriptions.map(fd => fd.forSize(width, height))

```

我们可以直接在画布上画出边界盒子来展示面部探测的结果:

```javascript
const detectionsArray = fullFaceDescriptions.map(fd => fd.detection)
faceapi.drawDetection(canvas, detectionsArray, { withScore: true })
```

![](https://ws3.sinaimg.cn/large/006tNbRwly1fy4xnpzmynj30gn09awhi.jpg)

面部标志也可以显示:

```javascript
const landmarksArray = fullFaceDescriptions.map(fd => fd.landmarks)
faceapi.drawLandmarks(canvas, landmarksArray, { drawLines: true })
```


![](https://ws2.sinaimg.cn/large/006tNbRwly1fy4xr19u4bj30gq069768.jpg)


通常,在做可视化时,都是使用绝对定位来重叠图片(参见github的实例)


## 面部识别

现在,我们需要知道如何获取所有面部的位置和描述特征, 我们得到一些图片显示单个人,计算出每个人的面部描述. 这些描述就是参考数据.

假定我们已经有了一些主题相关的图片,首先从 url或者使用 *faceapi.fetchImages*获取图片数据. 对于单张图片,都会定位脸部主体,并计算脸部描述,和输入图片是一样的操作.

```javascript
const labels = ['sheldon' 'raj', 'leonard', 'howard']

const labeledFaceDescriptors = await Promise.all(
  labels.map(async label => {
    // fetch image data from urls and convert blob to HTMLImage element
    const imgUrl = `${label}.png`
    const img = await faceapi.fetchImage(imgUrl)
    
    // detect the face with the highest score in the image and compute it's landmarks and face descriptor
    const fullFaceDescription = await faceapi.detectSingleFace(img).withFaceLandmarks().withFaceDescriptor()
    
    if (!fullFaceDescription) {
      throw new Error(`no faces detected for ${label}`)
    }
    
    const faceDescriptors = [fullFaceDescription.descriptor]
    return new faceapi.LabeledFaceDescriptors(label, faceDescriptors)
  })
)
```


注意,这里我们使用的是 *faceapi.detectSingleFace* , 将会返回要检测面部的最高得分,因为我们假设, 对于给定的标签,显示出的主体是唯一的.

现在,只剩下一件事,就是匹配参考数据和待检测面部的数据. 执行 *factapi.FaceMatcher* :

```javascript
// 0.6 is a good distance threshold value to judge
// whether the descriptors match or not
const maxDescriptorDistance = 0.6
const faceMatcher = new faceapi.FaceMatcher(labeledFaceDescriptors, maxDescriptorDistance)

const results = fullFaceDescriptions.map(fd => faceMatcher.findBestMatch(fd.descriptor))

```

面部匹配使用欧式距离作为相似度检测,欧式距离运转的很好. 最终我们为每张输入图片获得了一个最佳的匹配结果, 包含了最匹配的欧式距离结果的标签.

最后,我们使用边界盒子和标签画出结果:

```javascript
const boxesWithText = results.map((bestMatch, i) => {
  const box = fullFaceDescriptions[i].detection.box
  const text = bestMatch.toString()
  const boxWithText = new faceapi.BoxWithText(box, text)
  return boxWithText
})

faceapi.drawDetection(canvas, boxesWithText)

```

![](https://ws1.sinaimg.cn/large/006tNbRwly1fy4y6zdfc9j30kh089whp.jpg)


成功!  现在,我希望你已经使用api的初步印象. 我也建议你看看代码仓库中其他的实例. 

 `JavaScript` `Face Recognition` `TensorFlow`
 `Machine Learning` `Deep Learning`







