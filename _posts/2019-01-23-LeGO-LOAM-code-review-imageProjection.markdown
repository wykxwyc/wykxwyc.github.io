---
layout:     post
title:      "LeGO-LOAM 源码阅读笔记(imageProjecion.cpp)"
subtitle:   "Code Review of LeGO-LOAM(imageProjecion.cpp)"
date:       2019-01-23
author:     "wykxwyc"
header-img: "img/post-bg-slam-legoloam.jpg"
tags:
    - SLAM
    - LeGO-LOAM
---

> LeGO-LOAM是一种在LOAM之上进行改进的激光雷达建图方法，建图效果比LOAM要好，但是建图较为稀疏，计算量也更小了。
>
>本文原地址：[wykxwyc的博客](https://wykxwyc.github.io/2019/01/23/LeGO-LOAM-code-review-imageProjection/)
>
> github注释后LeGO-LOAM源码：[LeGO-LOAM_NOTED](https://github.com/wykxwyc/LeGO-LOAM_NOTED)
> 关于代码的详细理解，建议阅读：
> 
> 1.[地图优化代码理解](https://wykxwyc.github.io/2019/01/21/LeGO-LOAM-code-review-mapOptmization/)
> 
> 2.[图像重投影代码理解](https://wykxwyc.github.io/2019/01/23/LeGO-LOAM-code-review-imageProjection/)
> 
> 3.[特征关联代码理解](https://wykxwyc.github.io/2019/01/24/LeGO-LOAM-code-review-featureAssociation/)
>
> 4.[LeGO-LOAM中的数学公式推导](https://wykxwyc.github.io/2019/08/01/The-Math-Formula-in-LeGO-LOAM/)
> 
> 以上博客会随时更新，如果对你有帮助，请点击[注释代码](https://github.com/wykxwyc/LeGO-LOAM_NOTED)的github仓库右上角star按钮，你的鼓励将给我更多动力。



___目录___

* content
{:toc}

---

## imageProjecion.cpp
>imageProjecion.cpp进行的数据处理是图像映射，将得到的激光数据分割，并在得到的激光数据上进行坐标变换。

#### imageProjecion
imageProjecion()构造函数的内容如下：
1. 订阅话题：订阅来自velodyne雷达驱动的topic
	* `"/velodyne_points"`(`sensor_msgs::PointCloud2`)，订阅的subscriber是`subLaserCloud`。
2. 发布话题，这些topic有：
	* `"/full_cloud_projected"`(`sensor_msgs::PointCloud2`)
	* `"/full_cloud_info"`(`sensor_msgs::PointCloud2`)
	* `"/ground_cloud"`(`sensor_msgs::PointCloud2`)
	* `"/segmented_cloud"`(`sensor_msgs::PointCloud2`)
	* `"/segmented_cloud_pure"`(`sensor_msgs::PointCloud2`)
	* `"/segmented_cloud_info"`(`cloud_msgs::cloud_info`)
	* `"/outlier_cloud"`(`sensor_msgs::PointCloud2`)

然后分配内存(对智能指针初始化)，初始化各类参数。


---

#### cloudHandler
`void cloudHandler(const sensor_msgs::PointCloud2ConstPtr& laserCloudMsg)`是这个文件中最主要的一个函数。由它调用其他的函数：
```cpp
    void cloudHandler(const sensor_msgs::PointCloud2ConstPtr& laserCloudMsg){
        copyPointCloud(laserCloudMsg);
        findStartEndAngle();
        projectPointCloud();
        groundRemoval();
        cloudSegmentation();
        publishCloud();
        resetParameters();
    }
```

```
整体过程：
1. 复制点云数据
2. 找到开始和结束的角度
3. 移除地面点
4. 点云分块
5. 发布处理后的点云数据
6. 重置参数
```
上面第一部分复制点云数据是将ROS中的`sensor_msgs::PointCloud2ConstPtr`类型转换到pcl点云库指针。


---

#### findStartEndAngle
`void findStartEndAngle()`进行`segMsg`的开始和结束姿态的标记。因为开始和结束时的角度无法确定，而且两者之间的相对误差也是在一个范围之内的，所以代码要对这个问题进行处理。具体过程如下：
1. 计算开始和结束的角度值`segMsg.startOrientation`和`segMsg.endOrientation`。
2. 考虑结束的角度比开始时的角度值小的问题，对它进行处理。
```
// 开始和结束的角度差一般是多少？
// 一个velodyne 雷达数据包转过的角度多大？
// segMsg.endOrientation - segMsg.startOrientation范围为(0,4PI)
if (segMsg.endOrientation - segMsg.startOrientation > 3 * M_PI) {
		segMsg.endOrientation -= 2 * M_PI;
} else if (segMsg.endOrientation - segMsg.startOrientation < M_PI)
		segMsg.endOrientation += 2 * M_PI;
// segMsg.orientationDiff的范围为(PI,3PI),一圈大小为2PI，应该在2PI左右
segMsg.orientationDiff = segMsg.endOrientation - segMsg.startOrientation;
```


---



#### projectPointCloud
`void projectPointCloud()`将激光雷达得到的数据看成一个16x1800的点云阵列。然后根据每个点云返回的XYZ数据将他们对应到这个阵列里去。
1. 计算竖直角度，用`atan2`函数进行计算。
2. 通过计算的竖直角度得到对应的行的序号`rowIdn`，`rowIdn`计算出该点激光雷达是水平方向上第几线的。从下往上计数，-15度记为初始线，第0线，一共16线(`N_SCAN=16`)。
3. 求水平方向上的角度`horizonAngle = atan2(thisPoint.x, thisPoint.y) * 180 / M_PI;`。
4. 根据水平方向上的角度计算列向量`columnIdn`。
这里对数据的处理比较巧妙，一开始觉得很奇怪，但后来发现这样做其实让数据更不容易失真。
计算`columnIdn`主要是下面这三个语句：

```cpp
columnIdn = -round((horizonAngle-90.0)/ang_res_x) + Horizon_SCAN/2;
if (columnIdn >= Horizon_SCAN)
		columnIdn -= Horizon_SCAN;

if (columnIdn < 0 || columnIdn >= Horizon_SCAN)
		continue;
```
先把`columnIdn`从`horizonAngle:(-PI,PI]`转换到`columnIdn:[H/4,5H/4]`,然后判断`columnIdn`大小，再讲它的范围转换到了`[0,H] (H:Horizon_SCAN)`。
这样就把扫描开始的地方角度为0与角度为360的连在了一起，非常巧妙。
5. 接着在`thisPoint.intensity`中保存一个点的位置信息`rowIdn+columnIdn / 10000.0`，`fullInfoCloud`的点保存点的距离信息；



---


#### groundRemoval
`void groundRemoval()`由三个部分的程序组成。
1. 由上下两线之间点的XYZ位置得到两线之间的俯仰角，如果俯仰角在10度以内，则判定(i,j)为地面点,`groundMat[i][j]=1`，否则，则不是地面点，进行后续操作；
2. 找到所有点中的地面点，并将他们标记为-1，`rangeMat[i][j]==FLT_MAX`??? 判定为地面点的另一个条件。
3. 如果有节点订阅groundCloud，那么就需要把地面点发布出来。具体实现过程：把点放到groundCloud队列中去。这样就把地面点和非地面点标记并且区分开来了。


---


#### cloudSegmentation
`void cloudSegmentation()`进行的是点云分割的操作，将不同类型的点云放到不同的点云块中去，例如`outlierCloud`，`segmentedCloudPure`等。具体步骤：
1. 首先判断点云标签，这个点云没有进行过分类（在原先的处理中没有被分到地面点中去），则通过`labelComponents(i, j);`对点云进行分类。进行分类的过程在[labelComponents](#labelComponents)中进行介绍。
2. 分类完成后，找到可用的特征点或者地面点(不选择labelMat[i][j]=0的点)，按照它的标签值进行判断，将部分界外点放进`outlierCloud`中。`continue`继续处理下一个点。
3. 然后将大部分地面点去掉，省下的那些点进行信息的拷贝与保存操作。
4. 最后如果有节点订阅`SegmentedCloudPure`，那么把点云数据保存到`segmentedCloudPure`中去。


---


#### publishCloud
`void publishCloud()`发布各类点云数据。
```
// 发布各类点云内容
void publishCloud(){
	// 发布cloud_msgs::cloud_info消息
    segMsg.header = cloudHeader;
    pubSegmentedCloudInfo.publish(segMsg);

    sensor_msgs::PointCloud2 laserCloudTemp;

	// pubOutlierCloud发布界外点云
    pcl::toROSMsg(*outlierCloud, laserCloudTemp);
    laserCloudTemp.header.stamp = cloudHeader.stamp;
    laserCloudTemp.header.frame_id = "base_link";
    pubOutlierCloud.publish(laserCloudTemp);

	// pubSegmentedCloud发布分块点云
    pcl::toROSMsg(*segmentedCloud, laserCloudTemp);
    laserCloudTemp.header.stamp = cloudHeader.stamp;
    laserCloudTemp.header.frame_id = "base_link";
    pubSegmentedCloud.publish(laserCloudTemp);

    if (pubFullCloud.getNumSubscribers() != 0){
        pcl::toROSMsg(*fullCloud, laserCloudTemp);
        laserCloudTemp.header.stamp = cloudHeader.stamp;
        laserCloudTemp.header.frame_id = "base_link";
        pubFullCloud.publish(laserCloudTemp);
    }

    if (pubGroundCloud.getNumSubscribers() != 0){
        pcl::toROSMsg(*groundCloud, laserCloudTemp);
        laserCloudTemp.header.stamp = cloudHeader.stamp;
        laserCloudTemp.header.frame_id = "base_link";
        pubGroundCloud.publish(laserCloudTemp);
    }

    if (pubSegmentedCloudPure.getNumSubscribers() != 0){
        pcl::toROSMsg(*segmentedCloudPure, laserCloudTemp);
        laserCloudTemp.header.stamp = cloudHeader.stamp;
        laserCloudTemp.header.frame_id = "base_link";
        pubSegmentedCloudPure.publish(laserCloudTemp);
    }

    if (pubFullInfoCloud.getNumSubscribers() != 0){
        pcl::toROSMsg(*fullInfoCloud, laserCloudTemp);
        laserCloudTemp.header.stamp = cloudHeader.stamp;
        laserCloudTemp.header.frame_id = "base_link";
        pubFullInfoCloud.publish(laserCloudTemp);
    }
}
```

---


#### resetParameters
`void resetParameters()`贴一下代码凑字数：
```
// 初始化/重置各类参数内容
void resetParameters(){
    laserCloudIn->clear();
    groundCloud->clear();
    segmentedCloud->clear();
    segmentedCloudPure->clear();
    outlierCloud->clear();

    rangeMat = cv::Mat(N_SCAN, Horizon_SCAN, CV_32F, cv::Scalar::all(FLT_MAX));
    groundMat = cv::Mat(N_SCAN, Horizon_SCAN, CV_8S, cv::Scalar::all(0));
    labelMat = cv::Mat(N_SCAN, Horizon_SCAN, CV_32S, cv::Scalar::all(0));
    labelCount = 1;

    std::fill(fullCloud->points.begin(), fullCloud->points.end(), nanPoint);
    std::fill(fullInfoCloud->points.begin(), fullInfoCloud->points.end(), nanPoint);
}
```

---


#### labelComponents
` void labelComponents(int row, int col)`对点云进行标记。
- 用`queueIndX`，`queueIndY`保存进行分割的点云行列值，用`queueStartInd`作为索引。
- 求这个点的4个邻接点，求其中离原点距离的最大值`d1`最小值`d2`。根据下面这部分代码来评价这两点之间是否具有平面特征。注意因为两个点上下或者水平对应的分辨率不一样，所以`alpha`是用来选择分辨率的。

```
// alpha代表角度分辨率，
// Y方向上角度分辨率是segmentAlphaY(rad)
if ((*iter).first == 0)
		alpha = segmentAlphaX;
else
		alpha = segmentAlphaY;

// 通过下面的公式计算这两点之间是否有平面特征
// atan2(y,x)的值越大，d1，d2之间的差距越小,越平坦
angle = atan2(d2*sin(alpha), (d1 -d2*cos(alpha)));
```
- 在这之后通过判断角度是否大于60度来决定是否要将这个点加入保存的队列。加入的话则假设这个点是个平面点。
- 然后进行聚类，聚类的规则是：
	* 如果聚类超过30个点，直接标记为一个可用聚类，labelCount需要递增；
	* 如果聚类点数小于30大于等于5，统计竖直方向上的聚类点数
	* 竖直方向上超过3个也将它标记为有效聚类
	* 标记为999999的是需要舍弃的聚类的点，因为他们的数量小于30个


---

***以上是个人对LeGO-LOAM代码的一些笔记，很多都是猜的，不能保证正确***
***（imageProjection.cpp完）***