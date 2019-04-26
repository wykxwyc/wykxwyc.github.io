---
layout:     post
title:      "LeGO-LOAM论文内容翻译（精简)"
subtitle:   "Paper Traslation and Summary of LeGO-LOAM "
date:       2019-04-26
author:     "wykxwyc"
header-img: "img/post-bg-common-majime-punch.jpg"
tags:
    - SLAM
    - IMU
---

___目录___

* content
{:toc}

---

### topic1


旋转和平移完全解耦的好处是计算雅克比矩阵非常方便。比如，计算 oplusJacobian：


$$
\begin{align}
&\rm \frac{\partial x}{\partial \Delta x}:\\
&\rm \frac{\partial q}{\partial \delta \alpha} = \frac{\partial Q_{\bar{q}}\,\delta q}{\partial \delta \alpha} = \frac{1}{2}Q_{\bar{q}}I_{4\times 3}\\
&\rm \frac{\partial p}{\partial \delta p} = I_{3}\\
&\rm \frac{\partial q}{\partial \delta p} = \frac{\partial p}{\partial \delta \alpha} = 0
\end{align}
$$



### topic2

公式如下：

$$
\begin{align}
& p(x|y)=\frac{P(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\sum\limits_{x'}{p(y|x')p(x')}} \\ 
& p(x|y)=\frac{p(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\int{p(y|x')p(x')dx'}} \\ 
\end{align}
$$

