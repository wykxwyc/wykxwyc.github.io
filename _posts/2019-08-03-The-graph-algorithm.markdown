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

| 算法名称     | 时间复杂度                    | 空间复杂度 |  使用条件      |
| :---         |     :---:                     | :---:      |  :---:         |
| Dijstra      | O(V^2+E)/O(VlgV+ElgV)(最小堆) | O(V)       |  单源最短路径  |
| Floyd        | O(V^3)                        | O(V^2)     |  多源最短路径  |
| Bellman-Ford |                               |            |  单源最短路径  |
| SPFA         |                               |            |                |

##### DijkstraFloyd算法特点      
1.通常用于求单源最短路径；      
2.不允许图中带有负权值的边(也不允许有负权重的回路)；      
3.时间复杂度O(V^2+E)：所有的顶点都要被收录一次，所以外循环有V，每一个循环里面又要扫描一遍，V^2；收集的过程中涉及到每个邻接点，每条边又被访问了一遍；      
4.空间复杂度，存储到每个顶点的距离O(V)。      

##### Floyd算法特点     
1.通常用于求多源最短路径问题；      
2.允许图中带有负权值的边(但不允许有负权重的环)；
3.时间复杂度O(V^3)；      
4.空间复杂度O(V^2)：只存储每两个节点之间的距离以及路径；

##### Bellman-Ford算法特点          
1.通常用于求单源最短路径；      
2.允许图中带有负权值的边(但是不允许有负权重的回路)；     
3.时间复杂度
4.空间复杂度O()

### Dijkstra算法
##### Dijkstra算法的输入输出  

输入：整个网络拓扑和各链路的长度。      
输出：**源结点**到网络中**其他各结点**的最短路径。      

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
输出：图中**每个节点**到网络中**其他各结点**的最短路径。     

##### Floyd算法的原理
Floyd算法全称为Floyd-Warshall算法。      
Floyd-Warshall算法是解决任意两点间的最短路径的算法，可以处理有向图或负权值的最短路径问题，同时也被用于计算有向图的传递闭包（两个点是否连通）。      
Floyd-Warshall算法的原理是动态规划。      

若图G中有n个顶点的编号为1到n。      
设
$$
D_{i,j,k}
$$
为从
$$
i
$$
到
$$
j
$$
只以
$$
(1...k)
$$
集合中的节点为中间节点的最短路径长度。      
1.若最短路径经过点k，则
$$
D_{i,j,t}=D_{i,k,t-1} + D_{k,j,t-1}
$$
;      
2.若最短路径不经过点
$$
k
&&
，则
$$
D_{i,j,t} = D_{i,j,t-1}
$$
。
所以
$$
D_{i,j,k}=min(D_{i,k,t-1}+D{k,j,t-1})
$$
,在实际算法中，可以在原空间上进行迭代，这样可以将空间降到二维。


##### Floyd算法的C++实现
```
void Floyd( vector<vector<int>> graph, 
			vector<vector<int>>& dist,
			vector<vector<int>>& path){
    int n=graph.size();
    for ( int i = 0; i < n; i++ ){
        for( int j = 0; j < n; j++ ) {
            dist[i][j] = graph[i][j];
            path[i][j] = -1;
        }
    }
    for( int k = 0; k < n; k++ ){
        for(int  i = 0; i < n; i++ ){
            for( int j = 0; j < n; j++ ){
                if( dist[i][k] + dist[k][j] < dist[i][j] ) {
                    dist[i][j] = dist[i][k] + dist[k][j];
                    path[i][j] = k;
                }
            }
        }
    }
}

```


### Bellman-Ford算法
##### Bellman-Ford算法的输入输出

输入：整个网络拓扑和各链路的长度。      
输出：**源结点**到网络中**其他各结点**的最短路径。  

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
2.浙江大学算法与数据结构课(陈越老师等)      
3.博客网站：[link](https://dsqiu.iteye.com/blog/1689163)      
4.算法导论

