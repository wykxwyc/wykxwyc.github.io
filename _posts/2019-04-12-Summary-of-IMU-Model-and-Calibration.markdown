---
layout:     post
title:      "IMU模型以及校准知识总结"
subtitle:   "Summary of IMU model and calibration"
date:       2019-04-03
author:     "wykxwyc"
header-img: "img/post-IMU-model.jpg"
tags:
    - SLAM
    - IMU
---

旋转和平移完全解耦的好处是计算雅克比矩阵非常方便。比如，计算 oplusJacobian：

$$
\begin{align}
&\rm \frac{\partial x}{\partial \Delta x}:\\
&\rm \frac{\partial q}{\partial \delta \alpha} = \frac{\partial Q_{\bar{q}}\,\delta q}{\partial \delta \alpha} = \frac{1}{2}Q_{\bar{q}}I_{4\times 3}\\
&\rm \frac{\partial p}{\partial \delta p} = I_{3}\\
&\rm \frac{\partial q}{\partial \delta p} = \frac{\partial p}{\partial \delta \alpha} = 0
\end{align}
$$

