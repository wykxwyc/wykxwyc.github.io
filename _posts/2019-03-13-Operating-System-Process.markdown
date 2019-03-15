---
layout:     post
title:      "操作系统"
subtitle:   "Operating System"
date:       2019-03-13
author:     "wykxwyc"
header-img: "img/post-bg-operating-system.jpg"
tags:
    - OS
    - C++
---
> Qt is well known for its signals and slots mechanism. But how does it work?
> 

#### 多级页表和快表
>为了提高内存的空间利用率，页应该小，但是页小了页表就大了，页表很大之后，页表放置就成了问题。

假设计算机是32位的，内存大小最多是2^32=4G。如果页面尺寸为4K,那么就有4G/4K=1M=2^20个页面。

如果这1M个页表都要放在内存中，那么就需要4MB内存，如果系统并发10个线程，就需要40M内存。

实际上大部分逻辑地址是程序用不到的（假如一个hello word程序只用到了0~10这几个逻辑地址，那么它就不需要存除0-10以外的页号和页架号的对应关系）。

* 页表的查找：顺序查找代价太大，可以通过二分查找进行。

* 多级页表：既让内存连续，又让占用的内存少，类似于书的章目录和节目录

页目录表(章)+页表(节) 页目录中


