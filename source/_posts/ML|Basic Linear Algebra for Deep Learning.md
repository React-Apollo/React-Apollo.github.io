---
title: ML|Basic Linear Algebra for Deep Learning
date: 2018-04-07 07:52:49
categories: Basic Math
tags: [Linear Algebra,Machine Learning]
---
>  [原文地址](https://towardsdatascience.com/linear-algebra-for-deep-learning-f21d7e7d7f23)


# 深度学习的线性代数基础

{{TOC}}

![](https://ws1.sinaimg.cn/large/006tNc79gy1fq3r0xp90ij31hc0zkqls.jpg)
## 简介

线性代数对于计算机科学家而言有点,有点陌生,因为它是连续的区别于离散量. 线性代数是几何和泛函分析的核心.也是理解机器学习的很关键的前提,尤其是如果你是要编写深度学习的算法. 在机器学习入门时,不需要了解线性代数,但是在某些地方有了线性代数的基础,可以增加理解不同算法差异的直觉. 这会帮助你更好的决定如何来开发机器学习系统. 所以如果你真的想要在这个领域有所建树,线性代数的掌握是必须的. `在线性代数中,数据由线性方程组表征,线性方程组的形式是矩阵(matrices)和矢量(Vector)`.所以在线性代数中大多数情况下,我们在处理矩阵和矢量,而不是标量(scalar).如果拥有了类似 Nupmy一样的软件包,可以很容易的用几行代码来计算复杂的矩阵乘法. 

## 数学对象

![](https://ws2.sinaimg.cn/large/006tNc79gy1fq3ryi84z7j318g0g576v.jpg)

### 标量(Scalar)

标量是简单的数字,例如 23

### 矢量(Vector)

矢量是一组有序的数组,可以是行(row),也可以是列(column).一个矢量只有一个缩影,例如 V2指向矢量内的第二个值,在上图中指的的是-8.

![](https://ws3.sinaimg.cn/large/006tNc79gy1fq3ryx3rl0j318g0oztgu.jpg)

### 矩阵(Matrix)

矩阵是数字的二维数组. 它有两个索引,第一个指向 row,第二个指向 column.例如, M23指向第二行,第三列的值. 是"8".矩阵可以有多行多列. Vector 也是一个Matrix,只不过只有一行或者一列.

![](https://ws1.sinaimg.cn/large/006tNc79gy1fq3rz8f91ej318g0kyjza.jpg)

### 张量(Tensor)

Tensor 是一个数字数组, 以规则的网格来排布,拥有一个可变的轴.Tensor有三个轴,第一个指向行,第二个指向列,第三个指向轴.例如, V232指向第二行,第三列,第二个轴上的值.在下图中指向0 

![](https://ws1.sinaimg.cn/large/006tNc79gy1fq3rzn80ggj318g0otk41.jpg)

Tensor 是最重要的术语,因为 Tensor是一个多维数组,根据 indices 的不同,可以是一个 vector或者一个matrix,.例如一阶 tensor 就是一个 Vector(1索引),二阶(2索引),三阶(3 索引). 还有高阶索引(超过三阶的).

## 计算的规则

### 1.Matrix-Scalar 操作
如果是对一个矩阵执行加减乘除操作,只需要对矩阵的每个元素分别执行操作就可以了.

![](https://ws2.sinaimg.cn/large/006tNc79gy1fq3sph71zwj318g0jjjyq.jpg)


### 2.矩阵和矢量的乘法
矩阵和矢量的乘积得到一个与矩阵相同行数的矢量.

![](https://ws3.sinaimg.cn/large/006tNc79gy1fq3srouwivj318g0d8tdf.jpg)

![](https://ws4.sinaimg.cn/large/006tNc79gy1fq3su00glpj318g0din1t.jpg)


看看第二张图的计算步骤

1*1+3*5=16

4*1+0*5=4

2*1+1*5=7

另一个例子

![](https://ws2.sinaimg.cn/large/006tNc79gy1fq3sx73hn3j318g0g0q8w.jpg)


这是操作的 cheatsheet
![](https://ws4.sinaimg.cn/large/006tNc79gy1fq3syo285hj318g0mu115.jpg)


### 3.Matrix-Matrix 加法和减法
矩阵的加减法很简单,必须条件是两个举证要有相同的维度,结果也是同样的维度
![](https://ws3.sinaimg.cn/large/006tNc79gy1fq3t98tqcpj318g0dmn2b.jpg)

### 4.Matrix-Matrix 乘法

其实就是矩阵-矢量的乘法, 把第二个矩阵按列分割为矢量.第一个矩阵分别和矢量做乘法.最后放到一个新的矩阵中. 

![](https://ws2.sinaimg.cn/large/006tNc79gy1fq3tcx64r2j318g13h7i2.jpg)

矩阵乘法的 cheatsheet
![](https://ws1.sinaimg.cn/large/006tNc79gy1fq3tfy2j4ij318g0jutfb.jpg)

## 矩阵乘法的属性

矩阵乘法某些属性可以让我们在一个矩阵乘法中绑定一些计算. 接下来我们逐个介绍. 先从标量开始, 然后是矩阵. 这样做易于理解.

### 1.Not Commutative

标量的乘法是满足交换律的,矩阵的乘法不行.意思是,标量的乘法,7*3等同于3*7.但是矩阵的乘法 A*B 和 B*A是不同的. 

### 2.Associative

标量和矩阵都可以用组合律. 标量3(5*3)等同于(3*5)*3.矩阵一样, A(B*C)等同于(A*B)C.

### 3.Distributive

标量和矩阵都满足分配率的3(5+3)=3*5+3*3,A(B+C)=A*B+A*C

### 4.Identity Matrix
单位矩阵是一种特殊的矩阵,首先来看看单位是如何定义的. 数字1是一个单位,因为任何数乘与1都是它本身. 因此矩阵乘一个单位也等于自己.

如果一个矩阵乘与单位矩阵,就满足交换律:**A*I=I*A=A**

![](https://ws2.sinaimg.cn/large/006tNc79gy1fq3tu5773qj318g0j6tff.jpg)

## Matrix Inverse(逆) 和 Transpose(转置)
Inverse 和 Transpos 是矩阵的两个特殊的属性

### 1.Inverse

什么是 Inverse?一个数字乘与它的逆,等于1. 除了0,每个数字都有逆.

![](https://ws2.sinaimg.cn/large/006tNc79gy1fq3ukedjc8j318g0cv0xb.jpg)

并不是每个矩阵都有逆.

为什么需要逆这个计算? 因为我们不能除矩阵.矩阵没有除法的概念,但是我们可以给矩阵乘一个逆,结果和除法是一样的.

![](https://ws1.sinaimg.cn/large/006tNc79gy1fq3uoxzu1jj318g0cg432.jpg)

### 2.Transpose(转置)

本质上,转置就是一个矩阵沿着45度轴的一个镜像.获取一个矩阵的转置很容易. 第一个列变为转置矩阵的第一行,第二列变为转置矩阵的第二行.

![](https://ws4.sinaimg.cn/large/006tNc79gy1fq3uubkto2j318g0gidlm.jpg)

##  总结



##  Resources
Deep Learning (book) — Ian Goodfellow, Joshua Bengio, Aaron Courville
[https://machinelearningmastery.com/linear-algebra-machine-learning/](https://machinelearningmastery.com/linear-algebra-machine-learning/)
Andrew Ng’s Machine Learning course on Coursera
https://en.wikipedia.org/wiki/Linear_algebra
https://www.mathsisfun.com/algebra/scalar-vector-matrix.html
https://www.quantstart.com/articles/scalars-vectors-matrices-and-tensors-linear-algebra-for-deep-learning-part-1
https://www.aplustopper.com/understanding-scalar-vector-quantities/



