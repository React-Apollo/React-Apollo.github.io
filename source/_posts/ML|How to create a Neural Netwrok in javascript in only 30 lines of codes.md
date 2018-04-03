---
title: ML|How to create a Neural Netwrok in javascript in only 30 lines of codes
date: 2018-04-03 14:51:47
categories: 技术备忘
tags: [ML,Neural Network,Javascript]
---

![](https://ws1.sinaimg.cn/large/006tNc79gy1fpzgww6xjdj30zk0iwwn6.jpg)

>使用 synaptic.js 训练一个神经网络 . 解决 XOR  问题

> **xor 问题实例** 

| `num1` |`xor`  |`num2` |`res`  |
|:--|:--|:--|:--|
| 1 |`xor`  |1 |0  |
| 0 |`xor`  |0  |0  |
| 1 |`xor`  |0  |1  |
|  0|`xor`  |1  |1  |




![](https://ws4.sinaimg.cn/large/006tNc79gy1fpzgvth35qj31jk0qn0zb.jpg)

## Neurons and synapses

神经网络的构建块是: `neurons(神经元)`.  neurons类似函数,接收一些输入条件, 返回结果.有不同类型的 neurons,我们使用sigmoid neurons(多层感知),它接收给定的数字, 返回`0`到`1`之间的数字

下面的圆环就代表 sigmodi neurons. 接收`5`返回的是`1`. 箭头被称为 synapses(突触),负责把 neuron 连接到神经网络的其他层.
![](https://ws2.sinaimg.cn/large/006tNc79gy1fpzhcacdmgj30w50b73z3.jpg)

那么为什么**`5`**是红色的? 因为它是三个 synapses 的总和. 继续来分解一下:

最左侧的的两个绿色的值,和一个被称为 **bias** 的棕色值. 棕色的值是来源于另一个 neuron 的

首先两个输入值和他们的weights(权重)相乘,分别是蓝色的`7`,`3`. 

最后,我们在加上 bias ,最终得到红色的`5`. 这就是我们的人工神经网络的输入值

![](https://ws1.sinaimg.cn/large/006tNc79gy1fpzhnnvuryj30zm0c4glq.jpg)

在这个 sigmoid neuron 上, 所有的输入都被压缩为0~1之间的值.

如果把这些 neuron 的网络连接在一起,就可以得到一个 neural network. 形成的Neural work 会从前到后的传播,彼此通过 synapses 连接在一起. 如下图:

![](https://ws3.sinaimg.cn/large/006tNc79gy1fpzhruvj9uj309q08pt9c.jpg)


neural network 的目标是训练它做归纳,例如识别手写体的数字,或者垃圾邮件.要有一个好的归纳, 拥有正确的 **weights** **bias**是重点. 如上述实例中的蓝色和棕色数字.

在训练一个 neural network 时, 简单的给它展示一些手写数字的实例,让 network 可以预测正确的结果.

在每次预测后,将会要计算预测到底有多离谱,逐渐调整 weights 和 bias,直到 networks 在下一轮训练时做的更好. 这个学习过程被称为 backpropagation(反向传播).这个过程重复上千次.neural network 将会非常擅长归纳问题. 

backpropagation的工作技术超出了本教程.


```js
const { Layer, Network } = window.synaptic;
var inputLayer = new Layer(2);
var hiddenLayer = new Layer(3);
var outputLayer = new Layer(1);
```

接下来,把这些层连接起来,实例化一个新的 network,如下:

```js
inputLayer.project(hiddenLayer);
hiddenLayer.project(outputLayer);
var myNetwork = new Network({
 input: inputLayer,
 hidden: [hiddenLayer],
 output: outputLayer
});
```


由此得到一个2-3-1 network, 如下:

![](https://ws1.sinaimg.cn/large/006tNc79gy1fpzici19krj30sg0lcad7.jpg)


现在来训练这个 network:

```js
// train the network - learn XOR
var learningRate = .3;
for (var i = 0; i < 20000; i++) {
  // 0,0 => 0
  myNetwork.activate([0,0]);
  myNetwork.propagate(learningRate, [0]);
  // 0,1 => 1
  myNetwork.activate([0,1]);
  myNetwork.propagate(learningRate, [1]);
  // 1,0 => 1
  myNetwork.activate([1,0]);
  myNetwork.propagate(learningRate, [1]);
  // 1,1 => 0
  myNetwork.activate([1,1]);
  myNetwork.propagate(learningRate, [0]);
}
```

运行2000次, 每次向前,向后传播四次. 传递四个可能的值:`[0,0],[0,1],[1,0],[1,1]`

从`myNetwork.activate([0,0])`开始,`[0,0]`是发送的 network的数据点.这是向前传播,因此被称为 activating 网络. 每次向前传播之后,需要向后传播,这时, network 更新自己的 weights 和 biases.

backpropgation通过这一行代码执行:`myNetwork.propagate(learningRate,[0])`, `learningRate`是一个常量,告诉 newtork每次要调整多少 weights. 第二个参数`0`代表给定输入`[0,0]`应该得到的正确结果. 

**network 之后比较它的预期值和最终的正确值**,这会告诉 network 预期到底是正确还是错误的. 

network 用比较结果作为正确的 weights 和 bias 的基础,以便于下一次能更准确一点.

完成2000次处理过程以后,我们可以用四种可能的输入结果来检查 network 的激活情况.

```js
console.log(myNetwork.activate([0,0])); 
-> [0.015020775950893527]
console.log(myNetwork.activate([0,1]));
->[0.9815816381088985]
console.log(myNetwork.activate([1,0]));
-> [0.9871822457132193]
console.log(myNetwork.activate([1,1]));
-> [0.012950087641929467]
```



如果取整,就会得到争取的结果. 


