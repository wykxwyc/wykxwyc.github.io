---
layout:     post
title:      "蚁穴杂论"
subtitle:   "A little leak will sink a great ship"
date:       2019-07-12
author:     "wykxwyc"
header-img: "img/post-bg-common-seiigi-punch.jpg"
tags:
    - C++
---

___目录___

* content
{:toc}

---

##### C++中堆(优先队列)的使用
1.priority_queue默认使用最大堆，例如：      
```
std::priority_queue<int> q;
```      
上面这条语句声明了一个最大堆。      

2.最大堆与最小堆的声明：      
priority_queue<>默认是大根堆的，这是因为优先队列**队首指向最后，队尾指向最前面**的缘故      
也就是一个数组，如果用`std::less`排序(用<连接元素),优先队列的顶部一直都在数组末尾。      
```
// 最小堆
std::priority_queue<int, std::vector<int>, std::greater<int> > q2; 

// 最大堆
std::priority_queue<int, std::vector<int>, std::less<int> > q2;
```

3.自定义比较函数，生成不同的最大堆和最小堆      
```
// Using lambda to compare elements.
auto cmp = [](int left, int right) { return (left) < (right);}; // 大的数排前面
std::priority_queue<int, std::vector<int>, decltype(cmp)> q3(cmp);
```

4.[cppreference](https://en.cppreference.com/w/cpp/container/priority_queue)上的例子(经过修改)      
```
#include <functional>
#include <queue>
#include <vector>
#include <iostream>
 
template<typename T> void print_queue(T& q) {
    while(!q.empty()) {
        std::cout << q.top() << " ";
        q.pop();
    }
    std::cout << '\n';
}
 
int main() {
    std::priority_queue<int> q;
 
    for(int n : {1,8,5,6,3,4,0,9,7,2})
        q.push(n);
 
    print_queue(q);
 
    std::priority_queue<int, std::vector<int>, std::greater<int> > q2;
 
    for(int n : {1,8,5,6,3,4,0,9,7,2})
        q2.push(n);
 
    print_queue(q2);
 
    // Using lambda to compare elements.
    auto cmp = [](int left, int right) { return (left ) < (right );};
    std::priority_queue<int, std::vector<int>, decltype(cmp)> q3(cmp);
 
    for(int n : {1,8,5,6,3,4,0,9,7,2})
        q3.push(n);
 
    print_queue(q3);
}
```      
最后的输出结果：      
```
9 8 7 6 5 4 3 2 1 0 
0 1 2 3 4 5 6 7 8 9 
9 8 7 6 5 4 3 2 1 0
```



##### 记录一个C++设计模式的网站
[https://blog.csdn.net/u011012932/column/info/15392](https://blog.csdn.net/u011012932/column/info/15392)

##### 记录一个关于算法的博客网站
[https://blog.csdn.net/weixin_43795395/article/list/2?t=1&](https://blog.csdn.net/weixin_43795395/article/list/2?t=1&)

##### 卡特兰数是什么，有什么用
[https://blog.csdn.net/wookaikaiko/article/details/81105031](https://blog.csdn.net/wookaikaiko/article/details/81105031)      

##### Heyijia写的粒子滤波器(经过其他人合并)
[https://blog.csdn.net/piaoxuezhong/article/details/78619150](https://blog.csdn.net/piaoxuezhong/article/details/78619150)      
 
##### C++二分查找的函数
lower_bound( begin,end,num)：      
从数组的begin位置到end-1位置二分查找第一个大于或等于num的数字，找到返回该数字的地址，不存在则返回end。通过返回的地址减去起始地址begin,得到找到数字在数组中的下标。      

upper_bound( begin,end,num)：      
从数组的begin位置到end-1位置二分查找第一个大于num的数字，找到返回该数字的地址，不存在则返回end。通过返回的地址减去起始地址begin,得到找到数字在数组中的下标。      

例子：      
```
std::vector<int> v={10, 10, 10, 20, 20, 20, 30, 30};
 std::vector<int>::iterator low,up;
 low=std::lower_bound (v.begin(), v.end(), 20); //          ^
 up= std::upper_bound (v.begin(), v.end(), 20); //                   ^

 std::cout << "lower_bound at position " << (low- v.begin()) << '\n';
 std::cout << "upper_bound at position " << (up - v.begin()) << '\n';
```

输出：   
```
lower_bound at position 3
upper_bound at position 6

```

##### Unix网络编程中的五种IO模型
* Blocking IO - 阻塞IO      
* NoneBlocking IO - 非阻塞IO
* IO multiplexing - IO多路复用
* signal driven IO - 信号驱动IO
* asynchronous IO - 异步IO

摘录地址：[https://www.jianshu.com/p/b8203d46895c](https://www.jianshu.com/p/b8203d46895c)      


##### IO多路复用的三种机制select，poll，epoll
**1.select**      
1)使用select函数进行IO请求和同步阻塞模型没有太大的区别,甚至还多了添加监视socket，以及调用select函数的额外操作，效率更差.但在一个线程内同时处理多个socket的IO请求。      
2）每次调用select，都需要把fd_set集合从用户态拷贝到内核态，如果fd_set集合很大时，那这个开销也很大      
3）每次调用select都需要在内核遍历传递进来的所有fd_set，如果fd_set集合很大时，那这个开销也很大      
4）为了减少数据拷贝带来的性能损坏，内核对被监控的fd_set集合大小做了限制，并且这个是通过宏控制的，大小不可改变(限制为1024)      

**2.poll**      
poll只解决了上面的问题4，并没有解决问题2，3的性能开销问题。      

**3.epoll**      
1）基于事件驱动的I/O方式      
2）epoll没有描述符个数限制，使用一个文件描述符管理多个描述符      
3）将用户关心的文件描述符的事件存放到内核的一个事件表中，这样在用户空间和内核空间的copy只需一次      

参考链接：      
1.[https://www.jianshu.com/p/397449cadc9a](https://www.jianshu.com/p/397449cadc9a)      
2.[https://blog.csdn.net/daaikuaichuan/article/details/83862311](https://blog.csdn.net/daaikuaichuan/article/details/83862311)      


##### C++动态分配内存类名后有无括号的区别
1.没有定义默认构造函数(包括复合默认构造函数)      
使用`ClassName c=new ClassName()`后，类的成员变量初始化；      
使用`ClassName c=new ClassName`后，类的成员变量`没有`初始化；      
```
#include "solution.h"
#include <bits/stdc++.h>
using namespace std;

class ClassName {
public:
    int a;
};

class ClassName_2 {
public:
    int b;
};

int main(){
    ClassName *s=new ClassName();
    cout<<s->a<<endl;

    ClassName_2 *c=new ClassName_2;
    cout<<c->b<<endl;
    return 0;
}
```
输出结果：      
```
0
5374148
```

2.定义了默认构造函数(含复合默认构造函数)     
加不加括号，都调用类的默认构造函数，成员变量是否初始化和默认构造函数内部有关，由用户决定；      
```
#include "solution.h"
#include <bits/stdc++.h>
using namespace std;

class SubMatrix {
public:
    int a;
    SubMatrix(){
        cout<<"a="<<a<<endl;
    }
};

int main(){
    SubMatrix *s=new SubMatrix;
    cout<<s->a<<endl;
    return 0;
}

```
输出结果：      
```
a=5928760
5928760
```

##### 记录一个基础知识的github账号地址   
[https://github.com/CyC2018/CS-Notes/tree/master/docs/notes](https://github.com/CyC2018/CS-Notes/tree/master/docs/notes)


##### C++成员变量的初始化调用顺序
1.成员变量声明时初始化       
2.构造函数列表初始化(有个知识点，列表初始化的顺序是和声明的顺序一样的)      
3.构造函数内部赋值      

##### C++中的const的故事
1.类的成员变量有const修饰符：      
类的const成员变量是只读的，初始化只有两种方式，**定义的时候就初始化**，或者**列表初始化**。      

2.类的成员函数
`const int fun(const int* p) const{}`      
1)成员函数后面加const      
这个成员函数不能修改成员变量，解决方法是将成员变量修饰成mutable。      
2)成员函数最前面加const      
这个成员函数返回的是一个常量，如果不是指针，没什么特别的。      
但如果返回是一个指针，就有意义了，如下所示:
```
const int* get()
{ 
    auto x = new int(9);
     return x;
}
auto x = get();
*x = 10; // 错误，常量值不允许修改
delete x;
```

3.类的静态函数或者是非成员函数就不可以在函数名后面加上const，因为它没有this指针      


##### C++ 构造函数和析构函数是否可以是虚函数
**构造函数不能是虚函数**:      
* 从vptr角度解释       
虚函数的调用是通过虚函数表来查找的，而虚函数表由类的实例化对象的vptr指针指向，该指针存放在对象的内部空间中，需要调用构造函数完成初始化。如果构造函数是虚函数，那么调用构造函数就需要去找vptr，但此时vptr还没有初始化！      

* 从多态角度解释      
1.虚函数主要是实现多态，在运行时才可以明确调用对象，根据传入的对象类型来调用函数;      
2.构造函数是在创建对象时自己主动调用的，不可能通过父类的指针或者引用去调用,那使用虚函数也没有实际意义;      
3.调用构造函数时还不能确定对象的真实类型（由于子类会调父类的构造函数）;      
4.构造函数的作用是提供初始化，在对象生命期仅仅运行一次，不是对象的动态行为，没有必要成为虚函数。      

**析构函数可以且常常是虚函数**      
* C++类有继承时，析构函数必须为虚函数。如果不是虚函数，则使用时可能存在内存泄漏的问题。      






