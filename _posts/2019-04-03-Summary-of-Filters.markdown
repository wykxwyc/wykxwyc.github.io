---
layout:     post
title:      "滤波器总结"
subtitle:   "Summary of Filters"
date:       2019-04-03
author:     "wykxwyc"
header-img: "img/post-bg-filter.jpg"
tags:
    - SLAM
    - Filters
---

___目录___

* content
{:toc}

##### 杨亮《从贝叶斯开始学滤波》中一些问题
A Multi-State Constraint Kalman Filter for Vision-aided Inertial Navigation (Anastasios I. Mourikis and Stergios I. Roumeliotis)

这篇文章的主要思想就是用IMU和一个单目相机，单目相机的更新频率没有IMU的频率高。两个数据，要考虑两种数据的时间戳能否对上，在这种情况下，采用融合的方式。一个数据用来预测，另一个数据用来观测，然后用协方差来转换权重。

为什么要讲随机状态和估计？

因为这是一个概率问题。

预测的误差如何累积？

因为我在一个开环的估计里面，不断地走的时候没有人来告诉你走到哪里了，这个误差就会累积。

融合如何进行？

例如图形和加速度不同的信息如何融合？


##### 贝叶斯准则基本理论
贝叶斯准则的基本概念：
两个随机变量
$$
X
$$
和
$$
Y
$$
的联合分布由下式给出：

$$
p(x,y)=p(X=x,Y=y)
$$

如果X和Y相互独立，则有

$$
p(x,y)=p(x)p(y)
$$

在已经知道Y=y的基础上，求X的条件概率：

$$
p(x|y)=\frac{p(x,y)}{p(y)}
$$

如果X和Y相互独立：

$$
p(x|y)=\frac{p(x,y)}{p(y)}=p(x)
$$

全概率定理：

$$
\begin{align}
& p(x|y)=\frac{P(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\sum\limits_{x'}{p(y|x')p(x')}} \\ 
& p(x|y)=\frac{p(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\int{p(y|x')p(x')dx'}} \\ 
\end{align}
$$

贝叶斯准则：

$$
\begin{align}
 & p(x|y)=\frac{P(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\sum\limits_{x'}{p(y|x')p(x')}} \\ 
 & p(x|y)=\frac{p(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\int{p(y|x')p(x')dx'}} \\ 
\end{align}
$$

利用贝叶斯法则，有:

$$
p(x|z)=\frac{p(z|x)p(x)}{p(z)}\propto p(z|x)p(x)
$$

贝叶斯法则左侧通常称为后验概率，右侧 
$$
p(z|x)
$$
称为似然.

另一部分
$$
p(x)
$$
称为先验。直接求后验分布是困难的，但是求一个状态最优估计，使得在该状态下后验概率最大化(Maxminize a Posterior, MAP)，则是可行的：

$$
x_{M A P}^{*}=\arg \max p(x | z)=\arg \max p(z | x) p(x)
$$

贝叶斯法则的分母部分与带估计的状态x无关，因而可以忽略。贝叶斯法则告诉我们，求解最大后验概率相当于最大化似然和先验的乘积。进一步，没有先验时，可以求解x的最大似然估计（Maximize Likehood Estimation，MLE）。

$$
x^{*}_{M L E}=\arg \max p(z | x)
$$

似然：在现在的位姿下，可能产生怎样的观测数据。
因为我们知道观测数据，最大似然可以理解为：在什么样的状态下，最可能产生现在观测到的数据。

##### 贝叶斯滤波
$$
(\overset{\hat{\ }}{\mathop \cdot }\,)
$$
上帽子来表示后验估计

&&
(\overset{\vee }{\mathop \cdot }\,)
&&
下帽子来表示先验估计 

$$
p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0:k}\right)=\eta p\left(y_{k} | x_{k}\right) p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0:k-1}\right) \tag{1.1}
$$

式(1.1)根据全概率公理进行推导，对式(1.1)引入隐藏状态 ，右边部分第二项

$$
\begin{array}{l}{p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0 : k-1}\right)=\int p\left(x_{k}, x_{k-1} | \check{x}_{0}, v_{1 k}, y_{0 k-1}\right) d x_{k-1}} \\ {=\int p\left(x_{k} | x_{k-1}, \check{x}_{0}, v_{1:k}, y_{0:k-1}\right) p\left(x_{k-1} | \check{x}_{0}, v_{1 : k}, y_{0 : k-1}\right) d x_{k-1}}\end{array} \tag{1.2}
$$


