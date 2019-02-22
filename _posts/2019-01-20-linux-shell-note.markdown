---
layout:     post
title:      "Linux使用命令行收集"
subtitle:   "提高Linux使用效率"
date:       2019-01-21
author:     "wykxwyc"
header-img: "img/post-bg-linux-shell.jpg"
tags:
    - shell
    - Linux
---

> This document is not completed and will be updated anytime.


## ros常用命令
`rosnode list`
当前运行node信息

`rosnode info node_name`
   node详细信息

`rosnode kill node_name  `   
结束某个node

`roslaunch pkg_name file_name.launch   `
开启多个节点

`rosbag record <topic-name>`
记录某些topic到bag中

`rosbag record -a`
记录所有topic到bag中

`rosbag play <bag-files>`
播放bag

创建package
`cd ~/catkin_ws/src`
`catkin_create_pkg topic_demo roscpp rospy stdmsg`

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


## cmake编译
	cmake ..
	make
	make install

## 权限设置
`chmod -R a+rwx <filename>`

## g++编译生成hello.out
`g++ -o hello main.cpp`


## 打印寻找core的结果及时间
`time find / -name core`

## 将/user/local/bin加入路径
`PATH=$PATH:/user/local/bin`

## 在[当前.]目录下搜索含有boost内容的所有文件
`find ./ -name "*" | xargs grep "boost"`

## dg_console的依赖
`sudo apt-get install libedit-dev`

## 手柄查看信息
`sudo jstest /dev/input/js0`

## 列出/dev及其子目录下ttyUSB有关的文件与文件夹
ls -Rl /dev |grep ttyUSB

## 脚本开头
`#!/user/bin/env bash 或者 #!/bin/bash`

## 脚本只有读权限时执行
`bash thescript.sh  等价于有x权限  ./ thescript.sh`

## 删除变量
`unset variable_name `

## 得到一份shell 变量的拷贝
`export mynewvar `或者  `declare -x mynewvar`

## 得到同一目录下的终端
***Ctrl+shift+T***


## 查看硬盘容量
`df -h`


## terminator使用
***Ctrl+Shift+E*** 
垂直分割窗口

***Ctrl+Shift+O ***
水平分割窗口

***F11***
全屏

***exit***
 退出命令

***切换窗口***
alt+up/down/left/right