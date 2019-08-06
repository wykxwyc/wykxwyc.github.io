---
layout:     post
title:      "图的遍历以及图的最短路径问题"
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

| 算法名称     | 时间复杂度                         | 空间复杂度 |  使用条件      |
| :---         |     :---:                          | :---:      |  :---:         |
| Dijstra      | $O(V^2+E)/O(VlgV+ElgV)$   (最小堆) | $O(V)$       |  单源最短路径  |
| Floyd        | $$ O(V^3) $$                       | $O(V^2)$     |  多源最短路径  |
| Bellman-Ford |  $O(VE)$                           |  $ O(V) $  |  单源最短路径  |
| SPFA         |                                    |            |  单源最短路径  |

##### DijkstraFloyd算法特点      
1.通常用于求单源最短路径；      
2.不允许图中带有负权值的边(也不允许有负权重的回路)；      
3.时间复杂度 $O(V^2+E)$ ：所有的顶点都要被收录一次，所以外循环有 $$O(V)$$ ，每一个循环里面又要扫描一遍，$$O(V^2)$$；收集的过程中涉及到每个邻接点，每条边又被访问了一遍；      
4.空间复杂度，存储到每个顶点的距离$O(V)$。      

##### Floyd算法特点     
1.通常用于求多源最短路径问题；      
2.允许图中带有负权值的边(但不允许有负权重的环)；
3.时间复杂度$O(V^3)$：挑选任意两个顶点对$O(V^2)$,顶点对中间的节点$O(V)$,相乘；     
4.空间复杂度$O(V^2)$：只存储每两个节点之间的距离以及路径；

##### Bellman-Ford算法特点          
1.通常用于求单源最短路径；      
2.允许图中带有负权值的边(但是不允许有负权重的回路)；     
3.时间复杂度 $O(VE)$ ：最多会有 $V-1$ 层，每次遍历所有边进行更新 $O(E)$ ,相乘；   
4.空间复杂度 $O(V)$ ：只存储源点到所有点其他点的距离；      

##### SPFA算法特点
1.通常用于求单源最短路径；  

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

令 $D(v)$ 为源节点（图中的节点1）到某个节点 $v$ 的距离。      
$l(i,j)$$是节点 $i$ 到节点 $j$ 之间的距离。

算法只有两个部分：      
**1.初始化**      
令 $N$ 表示网络节点的集合。先令 $ N={ 1 } $ 。然后对所有不在 $N$ 中的节点，进行更新。更新的过程为：      
如果节点$v$与节点1直接相连， $D(v)=l(1,v)$ ;      
如果节点 $v$ 与节点1不直接相连， $D(v)=\infty$ 。      

**2.更新下一个节点**      
寻找一个不在 $N$ 中的节点 $w$ ，其 $D(w)$ 值最小(如果有很多个值是一样的，可以任选一个)。把
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
Bellman-Ford算法除了可求解边权均非负的单源点最短路径问题外,还能在更普遍的情况下（存在负权边）解决单源点最短路径问题。

##### Bellman-Ford算法的输入输出

输入：整个网络拓扑和各链路的长度(权重可以为负值)。      
输出：**源结点**到网络中**其他各结点**的最短路径。最后，如果检测到有负权重的环，直接返回警告。  

##### Bellman-Ford算法的原理
**Bellman-Ford算法流程分为三个阶段：**      
1.初始化：      
将除源点外的所有顶点的最短距离估计值`0->d[s],INT_MAX->d[t]`;

2.迭代求解：     
反复对边集E中的每条边进行松弛操作，使得顶点集V中的每个顶点v的最短距离估计值逐步逼近其最短距离；（运行|v|-1次）      

3.检验负权回路：      
判断边集E中的每一条边的两个端点是否收敛。如果存在未收敛的顶点，则算法返回false，表明问题无解；      
否则算法返回true，并且从源点可达的顶点v的最短距离保存在d[v]中。

**注意点：**      
1.Bellman算法中，如果存在从源点可达的**负权重**回路，则最短路径不存在，因为可以重复走这个回路，使路径无穷小。      

2.判断是否有负权重回路的方法：在进行了(V-1)次更新之后，再来更新一次，如果还能够让某个路径最短，则说明有负权重的边存在。      

3.Bellman-Ford算法是否一定要运行V-1次？      
运行次数可以少于V-1次，在某次循环中，考虑每条边后，都没有改变当前源点到所有顶点的最短路径长度，那么算法就可以提前结束了。      

4.Bellman-Ford算法的伪码描述：     
```
BeLLMAN_FORD(G,w,s)
	INTIALIZE-SINGLE-SOURCE(G,s)  // 用图中与s相连的边进行初始化
	for i=1 to |G.V|-1            // 循环V-1次
		for each edge(u,v) in G.E // 边的循环，用于更新距离
			RELAX(u,v,w)
	for each edge(u,v) in G.E     // 检查是否有负权重的环
		if v.d > u.d+w(u,v)
			return FALSE
	return TRUE

```

##### Bellman-Ford算法的C++实现

```

```

### SPFA算法   
Shortest Path Faster Algorithm,简称SPFA算法。      
算法是 Bellman-Ford算法 的队列优化算法的别称，通常用于求含负权边的单源最短路径，以及判负权环。      
SPFA 最坏情况下复杂度和朴素 Bellman-Ford 相同，为 O(VE)。

##### SPFA算法的输入输出


##### SPFA算法的原理


##### SPFA算法的C++实现



### 参考文献
1.百度文库：[https://wenku.baidu.com/view/060d9127bcd126fff7050b82.html](https://wenku.baidu.com/view/060d9127bcd126fff7050b82.html)      
2.浙江大学算法与数据结构课(陈越老师等)      
3.博客网站：[link](https://dsqiu.iteye.com/blog/1689163)      
4.算法导论      
5.百度百科：[link](https://baike.baidu.com/item/SPFA%E7%AE%97%E6%B3%95/8297411?fromtitle=SPFA&fromid=11018124&fr=aladdin)   
