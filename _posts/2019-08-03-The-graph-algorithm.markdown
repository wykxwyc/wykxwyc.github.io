---
layout:     post
title:      "图的搜索中的各种算法比较"
subtitle:   "The comparison of graph-based algorithm"
date:       2019-08-03
author:     "wykxwyc"
header-img: "img/post-bg-common-seiigi-punch.jpg"
tags:
    - Algorightm
    - Graph
---

___目录___

* content
{:toc}

---

### 各种图算法的比较

| 算法名称 | 时间复杂度 | 空间复杂度 |
| :---         |     :---:      |       :---: |
| Dijstra   | git status     | git status    |
| Floyd    | git diff       | git diff      |
| Bellman-Ford |            |               |
| SPFA |

##### DijkstraFloyd算法特点      
1.通常用于求单源最短路径；      
2.不允许图中带有负权值的边(也不允许有负权重的回路)；      

##### Floyd算法特点     
1.通常用于求多源最短路径问题；      
2.Floyd算法允许图中带有负权值的边(但不允许有负权重的环)；

##### Bellman-Ford算法特点          
1.适用目标：      
2.负权重情况：     


### Dijkstra算法
##### Dijkstra算法的输入输出  

输入：整个网络拓扑和各链路的长度。      
输出：源结点到网络中其他各结点的最短路径。      

##### 为什么Dijkstra不能有负权重的边？
![](/img/in-post/post-Graph-Algorithm/dijkstra_negtive.jpg)          
在上面这个图中，从源点S到终点T用Dijkstra算法求出来的是边长为2，而不是边长为1.      
过程：从S开始，到N为3，到T为2，这步选择T；      
然后找到V，但是T已经被加入到找到的点中去了，所以不再更新S到T的距离，因此不能找到边长为1（S->N->T）。


##### Dijkstra算法的运行过程
算法的大概过程为：从源节点开始，一步一步地寻找，每次找一个结点到源结点的最短路径，直到把所有的点都找到为止。

具体过程以图E-1的例子进行说明：      
![](/img/in-post/post-Graph-Algorithm/graph.jpg)      

令
$$
D(v)
$$
为源节点（图中的节点1）到某个节点
$$
v
$$
的距离。      
$$
l(i,j)
$$
是节点
$$
i
$$
到节点
$$
j
$$
之间的距离。

算法只有两个部分：      
**1.初始化**      
令
$$
N
$$
表示网络节点的集合。先令
$$
N={ 1 }
$$
。然后对所有不在N中的节点，进行更新。更新的过程为：      
如果节点
$$
v
$$
与节点1直接相连，
$$
D(v)=l(1,v)
$$
;      
如果节点
$$
v
$$
与节点1不直接相连，
$$
D(v)=\infty
$$
。

**2.更新下一个节点**      
寻找一个不在
$$
N
$$
中的节点
$$
w
$$，其
$$
D(w)
$$
值最小(如果有很多个值是一样的，可以任选一个)。把
$$
w
$$
加入到
$$
N
$$
中。然后对所有不在
$$
N
$$
中的节点
$$
v
$$
，用`D(v)=min(D(v),D(w)+l(w,v))`去更新原来的
$$
D(v)
$$
值。

**3.不断重复步骤2的过程，直到所有的节点都在N中为止**      


对图E-1进行Dijkstra算法进行搜索的表格如下所示：      
![](/img/in-post/post-Graph-Algorithm/table.jpg)      

##### Dijkstra算法的C++实现
```

```

### Floyd算法
##### Floyd算法的输入输出  

输入：整个网络拓扑和各链路的长度。      
输出：图中每个节点到网络中其他各结点的最短路径。     

##### Floyd算法的原理

##### Floyd算法的C++实现


### Bellman-Ford算法
##### Bellman-Ford算法的输入输出

##### Bellman-Ford算法的原理

##### Bellman-Ford算法的C++实现


### 公式的相关写法
##### 公式带标号：
$$
p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0:k}\right)=\eta p\left(y_{k} | x_{k}\right) p\left(x_{k} | \check{x}_{0}, v_{1:k}, y_{0:k-1}\right) \tag{1.1}
$$

##### 公式对齐方式
&写在哪里就从哪里开始对齐，例如：    
 
从开头对齐：     
$$
\begin{align}
& p(x|y)=\frac{P(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\sum\limits_{x'}{p(y|x')p(x')}} \\ 
& p(x|y)=\frac{p(y|x)p(x)}{p(y)}=\frac{p(y|x)p(x)}{\int{p(y|x')p(x')dx'}} \\ 
\end{align}
$$

从中间等号对齐：
$$
\begin{aligned} 
\check{x}_{k} &=\sum_{i=0}^{2 L} \alpha_{1} \check{x}_{k, i} \\ 
\check{P}_{k} &=\sum_{i=0}^{2 I} \alpha_{i}\left(\check{x}_{k, i}-\check{x}_{k}\right)\left(\check{x}_{k, i}-\check{x}_{k}\right)^{T} \\ 
\alpha_{i} &=\left\{\begin{array}{l}{\frac{k}{L+k}, i=0} \\ {\frac{1}{2} \frac{1}{L+k}}, others\end{array}\right. 
\end{aligned} \tag{1.29}
$$

### 参考文献
1.百度文库：[https://wenku.baidu.com/view/060d9127bcd126fff7050b82.html](https://wenku.baidu.com/view/060d9127bcd126fff7050b82.html)      
2.浙江大学算法与数据结构公开课(陈越老师等)      


