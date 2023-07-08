---
layout:     post
title:      "MongoDB知识图谱"
subtitle:   "Knowledge graph of MongoDB"
date:       2023-07-08
author:     "wykxwyc"
header-img: "img/post-bg-common-seiigi-punch.jpg"
tags:
    - MongoDB
    - Database
---

___目录___

* content
{:toc}

---

### 内容说明
MongoDB基础知识，MongoDB的使用，高级功能与底层设计是对[MongoDB知识图谱](https://www.toutiao.com/article/7081954023351321124/?upstream_biz=toutiao_pc&source=m_redirect&wid=1688789944127)这篇文章介绍的总结与归纳。      


### MongoDB基础知识      
核心特性：No Schema、高可用、分布式（可平行扩展），数据压缩功能。     

MongoDB高可用包括的功能：      
**MongoDB复制集群**      
主从节点，仲裁节点，Journal日志，oplog，checkpoint，节点选举方式      

**读写策略**      
写策略及包含的控制参数，读策略及对应的参数含义，读级别及对应的参数含义       

MongoDB可扩展性包括的功能：      
**分片集群架构**      

![](/img/in-post/post-Knowledge-graph-of-MongoDB/mongodb-shard.jpg)

`Config`, `Mongos`, `Mongod`负责的对应功能      

MongoDB的数据均衡策略及实现方式      

**分片算法**      
区间分片      

![](/img/in-post/post-Knowledge-graph-of-MongoDB/interval-shard.jpg)

hash分片      

![](/img/in-post/post-Knowledge-graph-of-MongoDB/interval-shard.jpg)


**数据压缩**      
MongoDB包含的压缩算法：      
Snappy：默认的压缩算法，压缩比 3 ～ 5 倍      
Zlib：高度压缩算法，压缩比 5 ～ 7 倍      
前缀压缩：索引用的压缩算法，简单理解就是丢掉重复的前缀      
zstd：MongoDB 4.2 之后新增的压缩算法，拥有更好的压缩率      

### MongoDB的使用      

**压缩比**      
Mongo 和 MySQL 下压缩比对比，可以看出 snapy 算法大概是 MySQL 的 3 倍，zlib 大概是 6 倍。      

**写性能**      

写性能的瓶颈在单个分片上      
当数据量小时是存内存读写，写性能很好，之后随着数量增加急剧下降，并最终趋于平稳，在 3000QPS(4 核 8G 的配置)。      
少量简单的索引对写性能影响不大      
分片集群批量写和逐条写性能无差异，而如果是复制集群批量写性能是逐条写性能的数倍。      

**读性能**      
按shardkey查：在 Mongos 处能算出具体的分片和 chunk，所以查询速度非常稳定，不会随着数据量变化。这种查询方式的瓶颈一般在 分片 Mongod 上，但也要注意 Mongos 配置不能太低。      
按索引查询：由于 Mongos 需要将数据全部转发到所有的分片，然后聚合全部结果返回客户端，因此性能瓶颈在 Mongos 上。如果索引数据不唯一，后端分片数更多，性能还会更低。      
全表扫描：客户端请求会到哪个 Mongos 是通过客户端 ip 的 hash 值决定的，因此同一个客户端所有请求一定会到同一个 Mongos，如果客户端过少的时候还会出现 Mongos 负载不均问题。      

**使用的注意点**      
分片建和分片算法选择      
预分片：避免chunk分裂和chunk迁移      
内存排序：查询的排序方式要和索引的相同      
链式复制：开启后写耗时会更长      


### 高级功能与底层设计      

**存储引擎**      
从 MongoDB 3.2 开始支持多种存储引擎：Wired Tiger，MMAPv1 和 In-Memory，其中默认为 Wired Tiger      

**数据结构**      
Oracle、SQL Server、DB2、MySQL (InnoDB) 这些传统的关系数据库依赖的底层存储引擎是基于 B+ Tree 开发的；而像 Cassandra、Elasticsearch (Lucene)、Google Bigtable、Apache HBase、LevelDB 和 RocksDB 这些当前比较流行的 NoSQL 数据库存储引擎是基于 LSM 开发的。MongoDB 虽然是 NoSQL 的，但是其存储引擎 Wired Tiger 却是用的 B+ Tree      

**Checkpoint**      
checkpoint 实现将内存中修改的数据持久化到磁盘，保证系统在因意外重启之后能快速恢复数据。checkpoint 本身数据也是会在每次 checkpoint 执行时落盘持久化的。      

**Chunk**       
chunk 本质上就是由一组 Document 组成的逻辑数据单元。它是分片集群用来管理数据存储和路由的基本单元。      
chunk分裂      

**一致性/高可用**      
BASE（Basically Available 基本可用、Soft state 软状态、Eventually consistent 最终一致性） 理论是在一致性和可用性上的平衡，现在大部分分布式系统都是基于 BASE 理论设计的，MongoDB 也是遵循此理论的。      

**选举与Raft协议**      
raft协议，投票规则，选举过程，catchup      

**主从同步**      
主从同步的本质实际上就是，Primary 节点接收客户端请求，将更新操作写到 oplog，然后 Secondary 从同步源拉取 oplog 并本地回放，实现数据的同步。      

同步源选取、oplog拉取与回放(oplog拉取与回放参考《MongoDB 复制技术内幕》)      

**索引**       
单字段索引，复合索引，多 key 索引，Hash 索引，地理位置索引，文本索引      

复合索引遵循前缀匹配，避免内存排序， 索引交集      
注意后台创建索引      


### 参考文献    
1.[MongoDB知识图谱](https://www.toutiao.com/article/7081954023351321124/?upstream_biz=toutiao_pc&source=m_redirect&wid=1688789944127)      
  