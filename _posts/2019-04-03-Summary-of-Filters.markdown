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
两个随机变量 $ X $ 和 $ Y $ 的联合分布由下式给出：

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

贝叶斯法则左侧通常称为后验概率，右侧$$p(z|x)$$称为似然，另一部分$$p(x)$$称为先验。直接求后验分布是困难的，但是求一个状态最优估计，使得在该状态下后验概率最大化(Maxminize a Posterior, MAP)，则是可行的：

$$
x_{M A P}^{*}=\arg \max p(x | z)=\arg \max p(z | x) p(x)
$$

