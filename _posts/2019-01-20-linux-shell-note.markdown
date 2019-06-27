---
layout:     post
title:      "Linux常用命令行记录"
subtitle:   ""
date:       2019-01-21
author:     "wykxwyc"
header-img: "img/post-bg-linux-shell.jpg"
tags:
    - shell
    - Linux
---

> This document is not completed and will be updated anytime.


#### ros常用命令
##### 初始化ROS工作空间
```
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
catkin_init_workspace
```

##### rosnode相关命令
`rosnode list`
当前运行node信息

`rosnode info node_name`
node详细信息

`rosnode kill node_name`   
结束某个node

`roslaunch pkg_name file_name.launch`
开启多个节点

##### rosbag命令
`rosbag record <topic-name>`
记录某些topic到bag中

`rosbag record -a`
记录所有topic到bag中

`rosbag play <bag-files>`
播放bag

```shell
rosbag play *.bag --clock --topic /velodyne_points /imu/data
```
播放当前目录下所有bag中的`/velodyne_points`和`/imu/data`topic

```shell
rosbag filter 2018-12-28-16-04-36.bag velodyne_and_imu_data_raw.bag "topic == '/velodyne_points' or topic == '/imu/data_raw'"
```
创建一个新bag`velodyne_and_imu_data_raw.bag`,在新bag中只有`/velodyne_points`和`/imu/data_raw`两个话题


创建package
```
cd ~/catkin_ws/src
catkin_create_pkg topic_demo roscpp rospy stdmsg
```

创建msg
`vi msg_name.msg`

根据当前的tf树创建一个pdf图
`rosrun tf view_frames`

查看当前的tf树
`rosrun rqt_tf_tree rqt_tf_tree`

查看两个frame之间的变换关系
`rosrun tf tf_echo <reference-frame> <target-frame>`

打印信息
`rostopic echo /velodyne_points`

启动map_server,发布地图
`rosrun map_server map_server my_map.yaml`


保存地图，[指定名称]
`rosrun map_server map_saver [-f my_map]`


创建新包
`catkin_create_pkg <pkg_name>  <depends>`
`ex：catkin_create_pkg test_pkg  roscpp rospy`

编译cartographer和velodyne
`catkin_make_isolated --install --use-ninja`

单独编译某几个package
`catkin_make --pkg <pkg name A> <pkg name B>`

发布tf信息 0.12x位移 0y位移 0.28z位移 0 0 0角度 10发布数据时间间隔      
`rosrun tf static_transform_publisher 0.12 0 0.28 0 0 0 base_link imu_link 10`

启动map_server，发布地图      
`rosrun map_server map_server my_map.yaml`

打印某几个坐标系之间的`tf`数据,(打印带有/base_footprint的tf数据,grep -C 10,匹配前后的10行 grep -A 前面,grep -B 后面)       
rostopic echo /tf |grep /base_footprint -C 10


###### cmake编译
```
cmake ..
make
make install //是否安装
```

解决`joyConfig.cmake`找不到的错误
```
sudo apt-get install ros-indigo-joy*
```


###### 权限设置
`chmod -R a+rwx <filename>`

###### g++编译生成hello.out
`g++ -o hello main.cpp`


###### 打印寻找core的结果及时间
`time find / -name core`

###### 将/user/local/bin加入路径
`PATH=$PATH:/user/local/bin`

###### 在[当前.]目录下搜索含有boost内容的所有文件
`find ./ -name "*" | xargs grep "boost"`

###### dg_console的依赖
`sudo apt-get install libedit-dev`

###### 手柄查看信息
`sudo jstest /dev/input/js0`

###### 列出/dev及其子目录下ttyUSB有关的文件与文件夹
`ls -Rl /dev |grep ttyUSB`

###### 脚本开头
`#!/user/bin/env bash 或者 #!/bin/bash`

###### 脚本只有读权限时执行
`bash thescript.sh  等价于有x权限  ./ thescript.sh`

###### 删除变量
`unset variable_name `

###### 得到一份shell 变量的拷贝
`export mynewvar `或者  `declare -x mynewvar`

###### 得到同一目录下的终端
`Ctrl+shift+T`


###### 查看硬盘容量
`df -h`

###### 让隐藏文件显示/隐藏 快捷键
`Ctrl+H`

#### terminator使用
`Ctrl+Shift+E`
垂直分割窗口

`Ctrl+Shift+O`
水平分割窗口

`F11`
全屏

`exit`
 退出命令

`alt+up/down/left/right`
切换窗口


#### git命令记录
从初始化一个workspace到上传并完全配置完的命令如下：

初始化
```
git init
```

配置本地用户
```
git config --global user.name "my_user_name"
```

配置本地邮箱
```
git config --global user.email "my_email@email.com"
```

产生公匙并保存在本地      
```
ssh-keygen -t rsa -C "my_email@email.com"
```

显示保存在`/c/Users/user_name/.ssh/`下的公匙并复制，然后打开github.com，在`Account settings`的`SSH and GPG Keys`中点击`New SSH Key`，并将复制的填入
`cat /c/Users/my_user_name/.ssh/id_rsa.pub`

添加远程仓库（如果没有则先新建远程仓库）      
```
git remote add origin git@github.com:user_name/repertory.git
```

从远端仓库中获得代码并与本地的合并      
```
git pull origin master
```

对所有文件都取消跟踪的话，就是      
```shell
git rm -r --cached . 　　//不删除本地文件
git rm -r --f . 　　//删除本地文件
```
 

对某个文件取消跟踪      
```shell
git rm --cached readme1.txt   //删除readme1.txt的跟踪，并保留在本地。
git rm --f readme1.txt    //删除readme1.txt的跟踪，并且删除本地文件。
```

