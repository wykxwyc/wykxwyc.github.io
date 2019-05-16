---
layout:     post
title:      "IMU模型以及校准知识总结"
subtitle:   "Summary of IMU model and calibration"
date:       2019-04-12
author:     "wykxwyc"
header-img: "img/post-bg-common-majime-face.jpg"
tags:
    - SLAM
    - IMU
---

___目录___

* content
{:toc}

---

### 对陀螺仪的噪声分析：艾伦方差(Allan Variance)
**艾伦方差**原本是用来衡量晶振的频率稳定性的，但也可以用来衡量内参噪声。   
这个方法很简单，可以鉴别和量化惯导传感器的不同噪声项。    
通过艾伦方差的方法可以得出的噪声项有5个，分别是：    
* 量化噪声（quantization noise）
* 角度随机游走（angle random walk）
* 偏置稳定性（bias instability）
* 速率随机游走(rate random walk)
* 速率斜坡（rate ramp）

对时域信号Ω(t)的Allen方差分析包括：   
* 计算Allen方差根/Allan偏差
* 将计算出来的值作为不同时间t的函数
* 分析对数-对数图中Allan偏差曲线的特征区域和尺度斜率，识别不同的噪声

### 针对陀螺仪数据绘制一张Allan偏差图以识别噪声
1.在陀螺仪静止时，获取陀螺仪的输出
$$
\Omega(t)
$$
，
采样数是
$$
N
$$
,
采样周期是
$$
\tau_{0}
$$
。       

2.令平均时间为
$$
\tau=m \tau_{0}
$$
，
$$
m
$$
可以任意选择，但是需要满足
$$
m<(N-1) / 2
$$
。      

3.将信号时间序列分成多个时间片，每个时间片长度满足
$$
\tau=m \tau_{0}
$$
，相邻两个时间片之间的区别就只在于其中一个周期
$$
\tau_{0}
$$
的时间不同，如下图所示：      
![](/img/in-post/post-Summary-of-imu/figure1-sample.png)

4.分片之后，可以有两种方式计算Allan方差：     
* 计算每个分片内采样数据的的平均值，在2.2节中提到；
* 对应于每种陀螺仪采样速率，输出角度θ，在2.1节中提到；      

5.最后对一个特定的𝜏值计算Allan偏差值，然后对不同的𝜏值计算Allan方差，就能得到Alla偏差图，见2.3节。

##### 2.1 通过输出角度计算Allan方差
对应于陀螺仪采样，可以计算出每个时刻的积分值（也就是角度），然后计算Allan方差。      
1.计算每次角速率采样时累积的θ值，通过下面的公式计算：      
$$
\theta(t)=\int^{t} \Omega\left(t^{\prime}\right) d t^{\prime} \tag{1}
$$

例如:     
$$
\begin{align}
t_{k} &=\tau_{0},2\tau_{0},3\tau_{0}(k=1,2,3) \\
\Omega_{k}\left(t\right) &=10,12,15 (k=1,2,3) \\
\theta_{k}(t) &=10\tau_{0},22\tau_{0},37\tau_{0}(k=1,2,3) \\
\end{align}
$$

2.当N个θ值被计算出来之后，通过公式(2)计算Allan方差：   
$$
\begin{align}
\sigma^{2}(\tau) &=\frac{1}{2 \tau^{2}}<\left(\theta_{k+2 m}-2 \theta_{k+m}+\theta_{k}\right)^{2}> \tag{2} \\
\theta^{2}(\tau) & =\frac{1}{2 \tau^{2}(N-2 m)} \sum_{k=1}^{N-2 m}\left(\theta_{\mathrm{K}+2 m}-2 \theta_{\mathrm{K}+m}+\theta_{\mathrm{K}}\right)^{2} \tag{3} \\
\end{align}
$$
上面公式（3）是通过公式（2）化简得到的。     
N是总的采样次数；      
$$
\tau=m \tau_{0}
$$
是分片时长；      
K（1，2,...,N）是一系列离散值。

##### 2.2 通过输平均输出速率采样值计算Allan方差
我们也可以通过计算每个分片时间内角速度的平均值来计算Allan方差.      
1.在
$$
K \tau_{0}
$$
和
$$
K \tau_{0}+\tau
$$
的时间范围内，平均值为：      
$$
\begin{align}
\overline{\Omega}_{\mathrm{K}}(\tau) & =\frac{1}{\tau} \int_{\mathrm{K} \tau_{0}}^{\mathrm{K} \tau_{0}+\tau} \Omega(t) dt \tag{4} \\
\overline{\Omega}_{\mathrm{K}}(\tau) & =\frac{\theta_{\mathrm{K}+m}-\theta_{\mathrm{K}}}{\tau} \tag{5} \\
\end{align}
$$      
公式（4）和公式（5）等价，都可以用来计算平均值。

例如：      
$$
\begin{align}
k &=2 \\
m &=3 \\
K\tau_{0}+\tau & =(K+m)\tau_{0} \\
\overline{\Omega}_{2}(\tau) & =\frac{\theta_{5}-\theta_{2}}{3 \tau_{0}} \tag{6} \\
\end{align}
$$      
当这样计算完N-m个值后，我们可以通过下面的公式计算Allan方差：      
$$
\begin{align}
\sigma^{2}(\tau) & =\frac{1}{2}<\left(\overline{\Omega}_{\mathrm{K}+m}(\tau)-\overline{\Omega}_{\mathrm{K}}(\tau)\right)^{2}> \tag{7} \\
\sigma^{2}(\tau) &=\frac{1}{2 m^{2}(N-2 m)} \sum_{j=1}^{N-2 m}\left\{\sum_{i=\mathrm{K}}^{j+m-1}\left(\overline{\Omega}_{\mathrm{K}+m}(\tau)-\overline{\Omega}_{\mathrm{K}}(\tau)\right)^{2}\right\} \tag{8} \\
\end{align}
$$     
公式（8）由公式（7）扩展得到。


##### 2.3 计算Allan偏差并画出Allan偏差图
通过公式（3）或者公式（8）得到对Allan方差（Allan Variance）取平方根，得到的这个值叫做Allan偏差（Allan Deviation）。
这个Allan偏差是针对一个特定的
$$
\tau
$$
的。即：      
$$
A D(\tau)=\sqrt{A V A R(\tau)} \tag{9}
$$      

因为提到过
$$
\tau
$$
是可以任意取值的





### topic2

公式如下：

$$
\begin{align}
& p(x|y)=\frac{P(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\sum\limits_{x'}{p(y|x')p(x')}} \\ 
& p(x|y)=\frac{p(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\int{p(y|x')p(x')dx'}} \\ 
\end{align}
$$

### 参考文献
[1] Miloš SOTÁK, František KMEC, Václav KRÁLÍK3, THE ALLAN VARIANCE METHOD FOR MEMS INERTIAL SENSORS PERFORMANCE CHARACTERIZATION, [link](https://pdfs.semanticscholar.org/754c/888068ca2d4cb2be42bc1936074f86353df1.pdf).  
[1] Freescale Semiconductor, Inc. Allan Variance: Noise Analysis for Gyroscopes, [link](http://cache.freescale.com/files/sensors/doc/app_note/AN5087.pdf).    
[1] Leslie Barreda Pupo, Characterization of Errors and Noises in MEMS Inertial Sensors Using Allan Variance Method, [link](https://upcommons.upc.edu/bitstream/handle/2117/103849/MScLeslieB.pdf?sequence=1&isAllowed=y).  
[1] Martin Vagner, MEMS GYROSCOPE PERFORMANCE COMPARISON USING ALLAN VARIANCE METHOD, [link](http://home.engineering.iastate.edu/~shermanp/AERE432/lectures/Rate%20Gyros/14-xvagne04.pdf).   

