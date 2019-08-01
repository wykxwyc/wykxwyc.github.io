---
layout:     post
title:      "LeGO-LOAM中的数学公式推导"
subtitle:   "The math formula in LeGO-LOAM"
date:       2019-08-01
author:     "wykxwyc"
header-img: "img/post-bg-common-seiigi-punch.jpg"
tags:
    - SLAM
    - LeGO-LOAM
---
> 记录重新读LeGO-LOAM的代码时看到的数学运算，记录这些数学运算背后的原理，会随时更新。

___目录___

* content
{:toc}

---

### featureAssociation中的数学公式

##### cornerOptimization中的协方差矩阵计算
* 随机变量的协方差是什么?      
1.在概率论和统计中，协方差是对两个随机变量联合分布线性相关程度的一种度量。两个随机变量越线性相关，协方差越大，完全线性无关，协方差为零。（线性无关并不代表完全无关，更不代表相互独立。）      
2.两个随机变量
$$
X
$$
与
$$
Y
$$
协方差的定义如下：      
$$
\operatorname{cov}(X, Y)=\mathrm{E}[(X-\mathrm{E}[X])(Y-\mathrm{E}[Y])] \tag{CO-1}
$$      

* 如何判断两个随机变量的相关程度？      
通过定义这两个变量之间的相关系数
$$
\eta
$$
进行判断：      
$$
\eta=\frac{\operatorname{cov}(X, Y)}{\sqrt{\operatorname{var}(X) \cdot \operatorname{var}(Y)}} \tag{CO-2}
$$      
1表示完全线性相关，−1表示完全线性负相关，0表示线性无关。线性无关并不代表完全无关，更不代表相互独立。      

* 样本的协方差矩阵      

1.设多维随机变量
$$
\mathbf{X}=\left[X_{1}, X_{2}, X_{3}, \dots, X_{n}\right]^{T}
$$
的协方差矩阵为
$$
\Sigma
$$
,则
$$
\Sigma_{i j}=\operatorname{cov}\left(X_{i}, X_{j}\right)=\mathrm{E}\left[\left(X_{i}-\mathrm{E}\left[X_{i}\right]\right)\left(X_{j}-\mathrm{E}\left[X_{j}\right]\right)\right]  \tag{CO-3}
$$
上式表示的是
$$
X_{i}
$$
和
$$
X_{j}
$$
之间的协方差，公式CO-3也揭示了协方差矩阵中每个元素的计算过程。其中还有：
$$
\begin{align}
\Sigma &=\mathrm{E}\left[(\mathbf{X}-\mathrm{E}[\mathbf{X}])(\mathbf{X}-\mathrm{E}[\mathbf{X}])^{T}\right] \\
&=\left[\begin{array}{cccc}{\operatorname{cov}\left(X_{1}, X_{1}\right)} & {\operatorname{cov}\left(X_{1}, X_{2}\right)} & {\dots} & {\operatorname{cov}\left(X_{1}, X_{n}\right)} \\ {\operatorname{cov}\left(X_{2}, X_{1}\right)} & {\operatorname{cov}\left(X_{2}, X_{2}\right)} & {\dots} & {\operatorname{cov}\left(X_{2}, X_{n}\right)} \\ {\vdots} & {\vdots} & {\ddots} & {\vdots} \\ {\operatorname{cov}\left(X_{n}, X_{1}\right)} & {\operatorname{cov}\left(X_{n}, X_{2}\right)} & {\cdots} & {\operatorname{cov}\left(X_{n}, X_{n}\right)}\end{array}\right] \\
&=\left[\begin{array}{cccc}{\mathrm{E}\left[\left(X_{1}-\mathrm{E}\left[X_{1}\right]\right)\left(X_{1}-\mathrm{E}\left[X_{1}\right]\right)\right]} & {\mathrm{E}\left[\left(X_{1}-\mathrm{E}\left[X_{1}\right]\right)\left(X_{2}-\mathrm{E}\left[X_{2}\right]\right)\right]} & {\cdots} & {\mathrm{E}\left[\left(X_{1}-\mathrm{E}\left[X_{1}\right]\right)\left(X_{n}-\mathrm{E}\left[X_{n}\right]\right)\right]} \\ {\mathrm{E}\left[\left(X_{2}-\mathrm{E}\left[X_{2}\right]\right)\left(X_{1}-\mathrm{E}\left[X_{1}\right]\right)\right]} & {\mathrm{E}\left[\left(X_{2}-\mathrm{E}\left[X_{2}\right]\right)\left(X_{2}-\mathrm{E}\left[X_{2}\right]\right)\right]} & {\cdots} & {\mathrm{E}\left[\left(X_{2}-\mathrm{E}\left[X_{2}\right]\right)\left(X_{n}-\mathrm{E}\left[X_{n}\right]\right)\right]} \\ {\vdots} & {\vdots} & {\ddots} & {\vdots} \\ {\mathrm{E}\left[\left(X_{n}-\mathrm{E}\left[X_{n}\right]\right)\left(X_{1}-\mathrm{E}\left[X_{1}\right]\right)\right]} & {\mathrm{E}\left[\left(X_{n}-\mathrm{E}\left[X_{n}\right]\right)\left(X_{2}-\mathrm{E}\left[X_{2}\right]\right)\right]} & {\cdots} & {\mathrm{E}\left[\left(X_{n}-\mathrm{E}\left[X_{n}\right]\right)\left(X_{n}-\mathrm{E}\left[X_{n}\right]\right)\right]}\end{array}\right]
\end{align}   \tag{CO-4}
$$

2.样本的协方差矩阵的计算      
样本集合为
$$
\left\{\mathbf{x}_{\cdot j}=\left[x_{1 j}, x_{2 j}, \ldots, x_{n j}\right]^{T} | 1 \leqslant j \leqslant m\right\}
$$
，m表示样本数量。则整个样本的协方差矩阵就是：      
$$
\begin{align}
\hat{\Sigma} &=\left[\begin{array}{cccc}{q_{11}} & {q_{12}} & {\cdots} & {q_{1 n}} \\ {q_{21}} & {q_{21}} & {\cdots} & {q_{2 n}} \\ {\vdots} & {\vdots} & {\ddots} & {\vdots} \\ {q_{n 1}} & {q_{n 2}} & {\cdots} & {q_{n n}}\end{array}\right] \\
&=\frac{1}{m-1}\left[\begin{array}{cccc}{\sum_{j=1}^{m}\left(x_{1 j}-\overline{x}_{1}\right)\left(x_{1 j}-\overline{x}_{1}\right)} & {\sum_{j=1}^{m}\left(x_{1 j}-\overline{x}_{1}\right)\left(x_{2 j}-\overline{x}_{2}\right)} & {\cdots} & {\sum_{j=1}^{m}\left(x_{1 j}-\overline{x}_{1}\right)\left(x_{n j}-\overline{x}_{n}\right)} \\ {\sum_{j=1}^{m}\left(x_{2 j}-\overline{x}_{2}\right)\left(x_{1 j}-\overline{x}_{1}\right)} & {\sum_{j=1}^{m}\left(x_{2 j}-\overline{x}_{2}\right)\left(x_{2 j}-\overline{x}_{2}\right)} & {\cdots} & {\sum_{j=1}^{m}\left(x_{2 j}-\overline{x}_{2}\right)\left(x_{n j}-\overline{x}_{n}\right)} \\ {\vdots} & {\vdots} & {\ddots} & {\vdots} \\ {\sum_{j=1}^{m}\left(x_{n j}-\overline{x}_{n}\right)\left(x_{1 j}-\overline{x}_{1}\right)} & {\sum_{j=1}^{m}\left(x_{n j}-\overline{x}_{n}\right)\left(x_{2 j}-\overline{x}_{2}\right)} & {\cdots} & {\sum_{j=1}^{m}\left(x_{n j}-\overline{x}_{n}\right)\left(x_{n j}-\overline{x}_{n}\right)}\end{array}\right] \\
&=\frac{1}{m-1} \sum_{j=1}^{m}\left(\mathbf{x} ._{j}-\overline{\mathbf{x}}\right)\left(\mathbf{x}_{ : j}-\overline{\mathbf{x}}\right)^{T}
\end{align}   \tag{OC-5}
$$

3.LeGO-LOAM的代码中的计算要点
**所以应用于LeGO-LOAM中的协方差计算只用采用公式OC-5中的计算方法就可以了,每个点云的维度为n=3,XYZ三个距离，一共有m=5个样本**   
**有一个区别就是代码中最后直接除以m=5，而公式OC-5中是除以m-1=4**


### mapOptmization中的数学公式


### transformFusion中的数学公式



### 参考文献及链接
1.苦力笨笨的博客:[https://www.cnblogs.com/terencezhou/p/6235974.html](https://www.cnblogs.com/terencezhou/p/6235974.html)      
2.

