---
layout:     post
title:      "ROS Navigation功能包介绍"
subtitle:   "Introduction to ROS Navigation stack"
date:       2019-06-08
author:     "wykxwyc"
header-img: "img/post-bg-common-majime-punch.jpg"
tags:
    - Navigation
    - ROS
---

___目录___

* content
{:toc}

---

### Global Planner
如果需要在导航包中使用`move_base`节点，我们需要一个`Global Planner`和一个`local planner`(一个老练的路径搜索器（pathfinder）外加一个琐细的运动算法（movement algorithm）可以找到一条路径)。      
依赖于`nav core::BaseGlobalPlanner`接口的全局规划器有3个：      
1.`carrot_planner`      
2.`navfn`      
3.`global planner`        

一个优秀的全局路径搜索器: 不要等到最后一刻才发现问题。

###### carrot_planner
carrot_planner检查需要到达的目标是不是一个障碍物，如果是一个障碍物，它就将目标点替换成一个附近可接近的点。因此，这个模块其实并没有做任何全局规划的工作。在复杂的室内环境中，这个模块并不实用。

##### navfn
`navfn`使用Dijkstra算法找到最短路径。      

##### global planner
`global planner`是`navfn`的升级版。它相对于`navfn`增加了更多的选项：      
1）支持A*算法；      
2）可以切换二次近似；      
3）切换网格路径；      

路径搜索中两种典型算法的对比(结果与速度)：
![dijkstra-BFS](/img/in-post/post-ROS-Navigation/dijkstra-BFS.jpg)

Global Planner : 路径搜索中最受欢迎的选择：A*算法      
1.和Dijkstra一样，A*能用于搜索最短路径      
2.和BFS一样，A*能用启发式函数引导它自己      
因此A*算法能做到又快又好。

A*算法的代价函数：      
$$
f(\boldsymbol{n})=\boldsymbol{g}(\boldsymbol{n})+\boldsymbol{h}(\boldsymbol{n})
$$      
$$
g(n)
$$
：初始结点到任意结点n的代价      
$$
h(n)
$$
：结点n到目标点的启发式评估代价

A*算法在有障碍和无障碍地图中的路径搜索结果：      
![A-star-1](/img/in-post/post-ROS-Navigation/A-star-1.png)      
上图为无障碍时      
![A-star-2](/img/in-post/post-ROS-Navigation/A-star-2.png)      
上图为有障碍时      

$$
h(n)=0
$$
，只有
$$
g(n)
$$
起作用，Dijkstra算法      
$$
h(n)
$$
比
$$
g(n)
$$
大很多，BFS(Best-First-Search)算法      

$$
h(n) \leq n
$$
到目标点，保证能找到一条最短路径，运行慢（尝试的可能变多）      
$$
h(n) = n
$$
到目标点，运行很快，非常完美，不太能发生      
$$
h(n) \geq n
$$
到目标点，不能保证找到一条最短路径，运行得更快      



### Local Planner
ROS中的local planner : DWA算法(dynamic window approach)      

DWA算法的流程如下：      
1.将机器人的控制空间离散化（dx,dy,dtheta）
2.对于每一个采样速度，从机器人的当前状态执行正向模拟，以预测如果在短时间段内采用采样速度将会发生什么
3.评估从正向模拟产生的每个轨迹使用包含诸如：障碍物接近度、目标接近度、全局路径接近度和速度等特征的度量，丢弃非法轨迹（与障碍物相撞的轨迹）
4.选择得分最高的轨迹，将相关联的速度发送给移动基站
5.清零然后重复以上过程

DWA算法的介绍：      
![DWA算法的介绍](/img/in-post/post-ROS-Navigation/dwa.jpg)      


### Costmap Parameters
[参看文献1或文献4]


### AMCL
AMCL是处理机器人定位的ROS包，是Navigation的一部分。      
AMCL(Adaptive Monte Carlo Localization)即自适应蒙特卡罗定位。      
AMCL cannot handle a laser that moves with respect to the base.      

![](/img/in-post/post-ROS-Navigation/amcl-frame.jpg)      

原理：粒子滤波器
1.每个样本存储表示机器人姿态的位置和方向数据。
2.粒子是随机抽样的，
3.当机器人移动时，粒子根据他们的状态记忆机器人的动作，进行重采样。

##### 粒子滤波器如何运用到AMCL
[未完善]


### 参考文献
1.[ROS Navigation Tuning Guide.pdf](https://github.com/wykxwyc/wykxwyc.github.io/blob/master/files/ROS%20Navigation%20Tuning%20Guide.pdf)      
2.[Amit’s A* Pages](http://theory.stanford.edu/~amitp/GameProgramming/)      
3.[Amit’s Game Programming Information](http://www-cs-students.stanford.edu/%7Eamitp/gameprog.html#Paths)      
4.[文献1的翻译](https://blog.csdn.net/zong596568821xp/article/details/77934688)      
5.[文献2和文献3关于A*算法的翻译-1](https://blog.csdn.net/denghecsdn/article/details/78778769)      
6.[文献2和文献3关于A*算法的翻译-2](https://blog.csdn.net/b2b160/article/details/4057781)      
