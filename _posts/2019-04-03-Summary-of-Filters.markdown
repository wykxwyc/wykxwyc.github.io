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

$$
(\overset{\vee }{\mathop \cdot }\,)
$$
下帽子来表示先验估计 

$$
p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0:k}\right)=\eta p\left(y_{k} | x_{k}\right) p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0:k-1}\right) \tag{1.1}
$$

式(1.1)根据全概率公理进行推导，对式(1.1)引入隐藏状态 ，右边部分第二项

$$
\begin{array}{l}{p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0 : k-1}\right)=\int p\left(x_{k}, x_{k-1} | \check{x}_{0}, v_{1 k}, y_{0 k-1}\right) d x_{k-1}} \\ {=\int p\left(x_{k} | x_{k-1}, \check{x}_{0}, v_{1:k}, y_{0:k-1}\right) p\left(x_{k-1} | \check{x}_{0}, v_{1 : k}, y_{0 : k-1}\right) d x_{k-1}}\end{array} \tag{1.2}
$$

$$
p\left(x_{k} | x_{k-1}, \check{x}_{0}, v_{1: k}, y_{0: k-1}\right)=p\left(x_{k} | x_{k-1}, v_{k}\right) \tag{1.3}
$$

$$
p\left(x_{k-1} | \check{x}_{0}, v_{1 : k}, y_{0 : k-1}\right)=p\left(x_{k-1} | \check{x}_{0}, v_{1 : k-1}, y_{0 : k-1}\right) \tag{1.4}
$$

&&
p\left(x_{k} | \check{x}_{0}, v_{1 : k}, y_{0: k}\right)=\eta p\left(y_{k} | x_{k}\right) \int p\left(x_{k} | x_{k-1}, v_{k}\right) p\left(x_{k-1} | \check{x}_{0}, v_{1 : k-1}, y_{0 : k-1}\right) d x_{k-1} \tag{1.5}
&&

&&
p\left(y_{k} | x_{k}\right)
&&
通过
$$g(\centerdot )
$$
更新，
$$
p\left(x_{k} | x_{k-1}, v_{k}\right)
$$
利用
$$
f(\centerdot )
$$
进行预测，
$$
p\left(x_{k-1} | \check{x}_{0}, v_{1 : k-1}, y_{0 : k-1}\right)
$$
是先验置信度。

##### 卡尔曼滤波器
预测的高斯分布：

$$
y\left(x, x_{p}, \delta_{p}\right)=\frac{1}{\sqrt{2 \pi \delta_{p}^{2}}} e^{-\frac{\left(x-x_{p}\right)^{2}}{2 \delta_{p}^{2}}}
$$

观测的高斯分布：

$$
y\left(x, x_{m}, \delta_{m}\right)=\frac{1}{\sqrt{2 \pi \delta_{m}^{2}}} e^{-\frac{\left(x-x_{w}\right)^{2}}{2 \delta_{n}^{2}}}
$$

有观测也有预测：

$$
y\left(x, x_{p}, \delta_{p}, x_{m}, \delta_{m}\right)=\frac{1}{2 \pi \sqrt{\delta_{m}^{2} \delta_{p}^{2}}} e^{-\frac{\left(x-x_{p}\right)^{2}}{2 \delta_{p}^{2}}-\frac{\left(x-x_{m}\right)^{2}}{2 \delta_{m}^{2}}}
$$

假设融合之后的为：

$$
y\left(x, x_{f}, \delta_{f}\right)=\frac{1}{\sqrt{2 \pi \delta_{f}^{2}}} e^{-\frac{\left(x-x_{f}\right)^{2}}{2 \delta_{f}^{2}}}
$$

求解得到

$$
\begin{array}{c}{\delta_{f}^{2}=\delta_{p}^{2}-\frac{\delta_{p}^{4}}{\delta_{p}^{2}+\delta_{m}^{2}}} \\ {x_{f}=x_{p}+\frac{\delta_{p}^{2}\left(x_{m}-x_{p}\right)}{\delta_{p}^{2}+\delta_{m}^{2}}}\end{array} \tag{1.6}
$$

通过上式 (1.6)可以看出，
当
$$
{\delta_{p}}
$$
越大时，说明我的预测值越不准，所以我更应该去相信测量值
$$
x_{m}
$$
，因此
$$
x_{m}
$$
的系数越接近于1，
$$
x_{f}
$$
越接近于
$$
x_{m}
$$
。


当
$$
{\delta_{p}}
$$
越小时，说明我的预测值越准，所以我更应该去相信测量值
$$
x_{p}
$$
，因此
$$
x_{m}
$$
的系数越接近于0，
$$
x_{f}
$$
越接近于$$
x_{p}
$$
。

因为测量值是从观测来的，所以有：

$$
Z=H X, \delta_{z}=H \delta_{m}
$$

根据式(1.6)，可以得到卡尔曼增益

$$
K=H \delta_{p}^{2} /\left(H^{2} \delta_{p}^{2}+\delta_{m}^{2}\right) \tag{1.7}
$$

式(1.7)在式(1.6)的增益的基础上有修改，主要是分子上的H。

从上面可以看出，卡尔曼滤波器就是根据高斯模型，简化了在计算时候的一些问题。然后再通过两个量之间的不确定量（方差）来融合估计和观测。

扩展卡尔曼滤波器和SLAM：
* 线性：KF
* 非线性或者部分非线性：EKF


##### 扩展卡尔曼滤波器（EKF）
将置信度和噪声限制为高斯分布，并且对运动模型和观测模型进行线性化，计算贝叶斯滤波中的积分（以及归一化积），得到EKF。
对于一般性的状态模型，定义研究对象的运动和观测模型为，

运动方程：
$$
x_{k}=f\left(x_{k-1}, v_{k}, w_{k}\right), k=1, \ldots, K \tag{1.8a}
$$

观测方程：
$$
y_{k}=g\left(x_{k}, n_{k}\right), k=0, \ldots, K \tag{1.8b}
$$

我们通过线性化将其恢复为加性噪声（取近似）的形式：

$$
\begin{aligned} x_{k} &=f\left(x_{k-1}, v_{k}\right)+w_{k} \\ y_{k} &=g\left(x_{k}\right)+n_{k} \end{aligned} \tag{1.9}
$$

式(1.9)其实是式(1.8)的特殊情况。
由于
$$
g(\centerdot )
$$
和
$$
f(\centerdot )
$$
的非线性特性，我们无法计算得到贝叶斯滤波器中的积分的解析解，转而使用线性化的方法，在当前均值（后验状态估计）处展开，对运动和观测模型进行线性化。

$$
f\left(x_{k-1}, v_{k}, w_{k}\right) \approx \check{x}_{k}+F_{k-1}\left(x_{k-1}-\check{x}_{k-1}\right)+w_{k}^{\prime} \tag{1.10}
$$

$$
g\left(x_{k}, n_{k}\right) \approx \check{y}_{k}+G_{k-1}\left(x_{k}-\check{x}_{k}\right)+n_{k}^{\prime} \tag{1.11}
$$

最后推导得到的EKF经典递归方程如下：

**预测：**
$$
\begin{aligned} \check{P}_{k} &=F_{k-1} \hat{P}_{k-1} F_{k-1}^{T}+Q_{k}^{\prime} \\ \hat{x}_{k} &=f\left(\check{x}_{k-1}, v_{k}, 0\right) \end{aligned} \tag{1.12}
$$

**卡尔曼增益：**
$$
\boldsymbol{K}_{k}=\boldsymbol{\check{P}}_{k} \boldsymbol{G}_{k}^{T}\left(\boldsymbol{G}_{k} \boldsymbol{\check{P}}_{k} \boldsymbol{G}_{k}^{T}+\boldsymbol{R}_{k}^{\prime}\right)^{-1} \tag{1.13}
$$

**更新：**
$$
\begin{aligned} \hat{P}_{k} &=\left(1-K_{k} G_{k}\right) \check{P}_{k} \\ \hat{x}_{k} &=\check{x}_{k}+K_{k}\left(y_{k}-g\left(\check{x}_{k}, 0\right)\right) \end{aligned} \tag{1.14}
$$

对以上公式的说明：

$$
F_{k-1}=\left.\frac{\partial f\left(x_{k-1}, v_{k}, w_{k}\right)}{\partial x_{k-1}}\right|_{\hat{x}_{k-1}, v_{k}, 0} \tag{1.15}
$$

