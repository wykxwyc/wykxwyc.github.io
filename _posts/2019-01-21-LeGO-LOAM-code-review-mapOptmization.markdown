---
layout:     post
title:      "LeGO-LOAM 源码阅读笔记（mapOptmization.cpp）"
subtitle:   "Code Review of LeGO-LOAM(mapOptmization.cpp)"
date:       2019-01-21
author:     "wykxwyc"
header-img: "img/post-bg-slam-legoloam.jpg"
tags:
    - SLAM
    - LeGO-LOAM
---

> This document haven't been completed and will be updated anytime.


___目录___

* content
{:toc}

---

#### mapOptmization.cpp总体功能论述
> mapOptmization.cpp进行的内容主要是地图优化，将得到的局部地图信息融合到全局地图中去。

#### mapOptimization.cpp整体框图架构

#### main
`main()`函数的关键代码就三条，也就是三个不同的线程，最重要的是`run()`函数：      
```cpp
std::thread loopthread(&mapOptimization::loopClosureThread, &MO);
std::thread visualizeMapThread(&mapOptimization::visualizeGlobalMapThread, &MO);
MO.run();
```

详细的`main()`函数的内容如下：      
```
int main(int argc, char** argv)
{
    ros::init(argc, argv, "lego_loam");
    
    ROS_INFO("\033[1;32m---->\033[0m Map Optimization Started.");
    
    mapOptimization MO;
    
    // std::thread 构造函数，将MO作为参数传入构造的线程中使用
    // 进行闭环检测与闭环的功能
    std::thread loopthread(&mapOptimization::loopClosureThread, &MO);
    	
    // 该线程中进行的工作是publishGlobalMap(),将数据发布到ros中，可视化
    std::thread visualizeMapThread(&mapOptimization::visualizeGlobalMapThread, &MO);
    
    ros::Rate rate(200);
    while (ros::ok())
    {
	    ros::spinOnce();
	    
	    MO.run();
	    
	    rate.sleep();
    }
    loopthread.join();
    visualizeMapThread.join();
    
    return 0;
}
```

#### loopthread
分析一下`std::thread loopthread(...)`部分的代码，它的主要功能是进行闭环检测和闭环修正。      
关于`std::thread`的构造函数可以参考[这里](http://www.cplusplus.com/reference/thread/thread/thread/ "std::thread")。      
其中关于std::thread 的构造函数之一：

```cpp
template <class Fn, class... Args>
explicit thread (Fn&& fn, Args&&... args);
```

`fn`是一个函数指针，指向成员函数（此处是`loopClosureThread()`）或一个可移动构造函数，关于`fn`的解释：

>***fn***
>A pointer to function, pointer to member, or any kind of move-constructible function object (i.e., an object whose class defines ***operator()***, including closures and function objects).
The return value (if any) is ignored.


`loopClosureThread()`函数：

```cpp
void loopClosureThread(){

    if (loopClosureEnableFlag == false)
        return;

    ros::Rate rate(1);
    while (ros::ok()){
        rate.sleep();
        performLoopClosure();
    }
}
```

上面主要的`performLoopClosure()`函数流程：
1. 先进行闭环检测`detectLoopClosure()`，如果返回`true`,则可能可以进行闭环，否则直接返回，程序结束。
2. 接着使用icp迭代进行对齐。
3. 对齐之后判断迭代是否收敛以及噪声是否太大，是则返回并直接结束函数。否则进行迭代后的数据发布处理。
4. 接下来得到`latestSurfKeyFrameCloud`和`nearHistorySurfKeyFrameCloudDS`之间的位置平移和旋转。
5. 然后进行图优化过程。

[RANSAC](https://baike.baidu.com/item/ransac/10993469?fr=aladdin "百度百科")（Random Sample Consensus）是根据一组包含异常数据的样本数据集，计算出数据的数学模型参数，得到有效样本数据的算法。


`performLoopClosure()`函数代码：
```
void performLoopClosure(){

    if (cloudKeyPoses3D->points.empty() == true)
        return;

    if (potentialLoopFlag == false){

        if (detectLoopClosure() == true){
            potentialLoopFlag = true;
            timeSaveFirstCurrentScanForLoopClosure = timeLaserOdometry;
        }
        if (potentialLoopFlag == false)
            return;
    }

    potentialLoopFlag = false;

    pcl::IterativeClosestPoint<PointType, PointType> icp;
    icp.setMaxCorrespondenceDistance(100);
    icp.setMaximumIterations(100);
    icp.setTransformationEpsilon(1e-6);
    icp.setEuclideanFitnessEpsilon(1e-6);
    // 设置RANSAC运行次数
    icp.setRANSACIterations(0);

    icp.setInputSource(latestSurfKeyFrameCloud);
    // 使用detectLoopClosure()函数中下采样刚刚更新nearHistorySurfKeyFrameCloudDS
    icp.setInputTarget(nearHistorySurfKeyFrameCloudDS);
    pcl::PointCloud<PointType>::Ptr unused_result(new pcl::PointCloud<PointType>());
    // 进行icp点云对齐
    icp.align(*unused_result);

    // 为什么匹配分数高直接返回???分数高代表噪声太多
    if (icp.hasConverged() == false || icp.getFitnessScore() > historyKeyframeFitnessScore)
        return;

    // 以下在点云icp收敛并且噪声量在一定范围内上进行
    if (pubIcpKeyFrames.getNumSubscribers() != 0){
        pcl::PointCloud<PointType>::Ptr closed_cloud(new pcl::PointCloud<PointType>());
		// icp.getFinalTransformation()的返回值是Eigen::Matrix<Scalar, 4, 4>
        pcl::transformPointCloud (*latestSurfKeyFrameCloud, *closed_cloud, icp.getFinalTransformation());
        sensor_msgs::PointCloud2 cloudMsgTemp;
        pcl::toROSMsg(*closed_cloud, cloudMsgTemp);
        cloudMsgTemp.header.stamp = ros::Time().fromSec(timeLaserOdometry);
        cloudMsgTemp.header.frame_id = "/camera_init";
        pubIcpKeyFrames.publish(cloudMsgTemp);
    }   

    float x, y, z, roll, pitch, yaw;
    Eigen::Affine3f correctionCameraFrame;
    correctionCameraFrame = icp.getFinalTransformation();
	// 得到平移和旋转的角度
    pcl::getTranslationAndEulerAngles(correctionCameraFrame, x, y, z, roll, pitch, yaw);
    Eigen::Affine3f correctionLidarFrame = pcl::getTransformation(z, x, y, yaw, roll, pitch);
    Eigen::Affine3f tWrong = pclPointToAffine3fCameraToLidar(cloudKeyPoses6D->points[latestFrameIDLoopCloure]);
    Eigen::Affine3f tCorrect = correctionLidarFrame * tWrong;
    pcl::getTranslationAndEulerAngles (tCorrect, x, y, z, roll, pitch, yaw);
    gtsam::Pose3 poseFrom = Pose3(Rot3::RzRyRx(roll, pitch, yaw), Point3(x, y, z));
    gtsam::Pose3 poseTo = pclPointTogtsamPose3(cloudKeyPoses6D->points[closestHistoryFrameID]);
    gtsam::Vector Vector6(6);
    float noiseScore = icp.getFitnessScore();
    Vector6 << noiseScore, noiseScore, noiseScore, noiseScore, noiseScore, noiseScore;
    constraintNoise = noiseModel::Diagonal::Variances(Vector6);

    std::lock_guard<std::mutex> lock(mtx);
    gtSAMgraph.add(BetweenFactor<Pose3>(latestFrameIDLoopCloure, closestHistoryFrameID, poseFrom.between(poseTo), constraintNoise));
    isam->update(gtSAMgraph);
    isam->update();
    gtSAMgraph.resize(0);

    aLoopIsClosed = true;
}
```

---

#### visualizeMapThread

`visualizeGlobalMapThread()`代码：
```cpp
void visualizeGlobalMapThread(){
    ros::Rate rate(0.2);
    while (ros::ok()){
        rate.sleep();
        publishGlobalMap();
    }
}
```

`publishGlobalMap()`主要进行了3个步骤：
1. 通过KDTree进行最近邻搜索;
2. 通过搜索得到的索引放进队列;
3. 通过两次下采样，减小数据量;

`publishGlobalMap()`代码：
```
void publishGlobalMap(){

    if (pubLaserCloudSurround.getNumSubscribers() == 0)
        return;

    if (cloudKeyPoses3D->points.empty() == true)
        return;

    std::vector<int> pointSearchIndGlobalMap;
    std::vector<float> pointSearchSqDisGlobalMap;

    mtx.lock();
    kdtreeGlobalMap->setInputCloud(cloudKeyPoses3D);
    // 通过KDTree进行最近邻搜索
    kdtreeGlobalMap->radiusSearch(currentRobotPosPoint, globalMapVisualizationSearchRadius, pointSearchIndGlobalMap, pointSearchSqDisGlobalMap, 0);
    mtx.unlock();

    for (int i = 0; i < pointSearchIndGlobalMap.size(); ++i)
      globalMapKeyPoses->points.push_back(cloudKeyPoses3D->points[pointSearchIndGlobalMap[i]]);

    // 对globalMapKeyPoses进行下采样
    downSizeFilterGlobalMapKeyPoses.setInputCloud(globalMapKeyPoses);
    downSizeFilterGlobalMapKeyPoses.filter(*globalMapKeyPosesDS);

    for (int i = 0; i < globalMapKeyPosesDS->points.size(); ++i){
		int thisKeyInd = (int)globalMapKeyPosesDS->points[i].intensity;
		*globalMapKeyFrames += *transformPointCloud(cornerCloudKeyFrames[thisKeyInd],   &cloudKeyPoses6D->points[thisKeyInd]);
		*globalMapKeyFrames += *transformPointCloud(surfCloudKeyFrames[thisKeyInd],    &cloudKeyPoses6D->points[thisKeyInd]);
		*globalMapKeyFrames += *transformPointCloud(outlierCloudKeyFrames[thisKeyInd], &cloudKeyPoses6D->points[thisKeyInd]);
    }

    // 对globalMapKeyFrames进行下采样
    downSizeFilterGlobalMapKeyFrames.setInputCloud(globalMapKeyFrames);
    downSizeFilterGlobalMapKeyFrames.filter(*globalMapKeyFramesDS);

    sensor_msgs::PointCloud2 cloudMsgTemp;
    pcl::toROSMsg(*globalMapKeyFramesDS, cloudMsgTemp);
    cloudMsgTemp.header.stamp = ros::Time().fromSec(timeLaserOdometry);
    cloudMsgTemp.header.frame_id = "/camera_init";
    pubLaserCloudSurround.publish(cloudMsgTemp);  

    globalMapKeyPoses->clear();
    globalMapKeyPosesDS->clear();
    globalMapKeyFrames->clear();
    globalMapKeyFramesDS->clear();     
}
```


---

### run

`run()`是`mapOptimization`类的一个成员变量
`run()`的运行流程：
1. 判断是否有新的数据到来并且时间差值小于0.005；
2. 如果`timeLaserOdometry - timeLastProcessing >= mappingProcessInterval`，则进行以下操作：
2.1. 将坐标转移到世界坐标系下，得到可用于建图的Lidar坐标，即修改transformTobeMapped的值；
2.2. 抽取周围的关键帧；
2.3. 下采样当前scan；
2.4. 当前scan进行图优化过程；
2.5. 保存关键帧和因子；
2.6. 校正位姿；
2.7. 发布Tf；
2.8. 发布关键位姿和帧数据；

`run()`函数的代码如下：
```cpp
void run(){

    if (newLaserCloudCornerLast  && std::abs(timeLaserCloudCornerLast  - timeLaserOdometry) < 0.005 &&
        newLaserCloudSurfLast    && std::abs(timeLaserCloudSurfLast    - timeLaserOdometry) < 0.005 &&
        newLaserCloudOutlierLast && std::abs(timeLaserCloudOutlierLast - timeLaserOdometry) < 0.005 &&
        newLaserOdometry)
    {

        newLaserCloudCornerLast = false; newLaserCloudSurfLast = false; newLaserCloudOutlierLast = false; newLaserOdometry = false;

        std::lock_guard<std::mutex> lock(mtx);

        if (timeLaserOdometry - timeLastProcessing >= mappingProcessInterval) {

            timeLastProcessing = timeLaserOdometry;

            transformAssociateToMap();

            extractSurroundingKeyFrames();

            downsampleCurrentScan();

            scan2MapOptimization();

            saveKeyFramesAndFactor();

            correctPoses();

            publishTF();

            publishKeyPosesAndFrames();

            clearCloud();
        }
    }
}
```

---

### mapOptimization
mapOptimization类主要是其构造函数`mapOptimization()`的操作上有一些内容：

在构造函数中，mapOptimization订阅了5个话题，发布了6个话题。
订阅的话题：
1. `/laser_cloud_corner_last`
2. `/laser_cloud_surf_last`
3. `/outlier_cloud_last`
4. `/laser_odom_to_init`
5. `/imu/data`

发布的话题：
1. `/key_pose_origin`
2. `/laser_cloud_surround`
3. `/aft_mapped_to_init`
4. `/history_cloud`
5. `/corrected_cloud`
6. `/recent_cloud`

另外，初始化了`ISAM2`对象，以及下采样参数，和分配了内存。


---

### transformAssociateToMap

`transformAssociateToMap()`函数将坐标转移到世界坐标系下，得到可用于建图的Lidar坐标，即修改了transformTobeMapped的值，其具体公式并没有弄清楚。


---

### extractSurroundingKeyFrames
`extractSurroundingKeyFrames()`抽取周围关键帧。
该部分的自然语言表述如下：
```
extractSurroundingKeyFrames(){
	if(cloudKeyPoses3D为空)
		return；
	if(进行闭环过程){
		若recentCornerCloudKeyFrames中的点云数量不够，
			清空后重新塞入新的点云直至数量够。
		否则pop队列recentCornerCloudKeyFrames最前端的一个，再往队列尾部push一个；
		*laserCloudCornerFromMap += *recentCornerCloudKeyFrames[i];
        *laserCloudSurfFromMap   += *recentSurfCloudKeyFrames[i];
        *laserCloudSurfFromMap   += *recentOutlierCloudKeyFrames[i];
	}else{
		/*这里不进行闭环过程*/
		1.进行半径surroundingKeyframeSearchRadius内的邻域搜索
		2.双重循环，不断对比surroundingExistingKeyPosesID和surroundingKeyPosesDS中点的index,
			如果能够找到一样，说明存在关键帧。然后在队列中去掉找不到的元素，留下可以找到的。
		3.再来一次双重循环，这部分比较有技巧，
			这里把surroundingExistingKeyPosesID内没有对应的点放进一个队列里，
			这个队列专门存放周围存在的关键帧，
			但是和surroundingExistingKeyPosesID的点不在同一行。
			关于行，需要参考intensity数据的存放格式，
			整数部分和小数部分代表不同意义。
	}
	不管是否进行闭环过程，最后的输出都要进行一次下采样减小数据量的过程。
	最后的输出结果是laserCloudCornerFromMapDS和laserCloudSurfFromMapDS。
	
}
```

---

### downsampleCurrentScan
`downsampleCurrentScan()`这部分可以说的不多，代码也很短。
总体过程如下:

	1. 下采样laserCloudCornerLast得到laserCloudCornerLastDS；
	2. 下采样laserCloudSurfLast得到laserCloudSurfLastDS;
	3. 下采样laserCloudOutlierLast得到laserCloudOutlierLastDS;
	4. laserCloudSurfLastDS和laserCloudOutlierLastDS相加，得到laserCloudSurfTotalLast；
	5. 下采样得到laserCloudSurfTotalLast，得到得到laserCloudSurfTotalLastDS;


---


### scan2MapOptimization
`scan2MapOptimization()`是一个对代码进行优化控制的函数，主要在里面调用**面优化**，**边缘优化**以及**L-M优化**。
该函数控制了进行优化的最大次数为10次，直接贴出代码如下：
```cpp
void scan2MapOptimization(){

    if (laserCloudCornerFromMapDSNum > 10 && laserCloudSurfFromMapDSNum > 100) {

        kdtreeCornerFromMap->setInputCloud(laserCloudCornerFromMapDS);
        kdtreeSurfFromMap->setInputCloud(laserCloudSurfFromMapDS);

        for (int iterCount = 0; iterCount < 10; iterCount++) {

            laserCloudOri->clear();
            coeffSel->clear();

            cornerOptimization(iterCount);
            surfOptimization(iterCount);

            if (LMOptimization(iterCount) == true)
                break;              
        }

        transformUpdate();
    }
}
```

上面`laserCloudCornerFromMapDSNum`和`laserCloudSurfFromMapDSNum`是我们在函数`extractSurroundingKeyFrames()`中刚刚更新的。

关于上面的三个优化函数，在下文中有对优化函数的详细分析：      
1.关于特征边缘的优化：[cornerOptimization](https://wykxwyc.github.io/2019/01/21/LeGO-LOAM-code-review-mapOptmization/#corneroptimization);      
2.关于特征平面的优化：[surfOptimization](https://wykxwyc.github.io/2019/01/21/LeGO-LOAM-code-review-mapOptmization/#surfOptimization);      
3.关于特征边缘和特征平面的联合L-M优化方法：[LMOptimization](https://wykxwyc.github.io/2019/01/21/LeGO-LOAM-code-review-mapOptmization/#LMOptimization)。      


---

### saveKeyFramesAndFactor
`void saveKeyFramesAndFactor()`保存关键帧和进行优化的功能。
整个函数的运行流程如下:
```
saveKeyFramesAndFactor(){
	1. 把上次优化得到的transformAftMapped(3:5)坐标点作为当前的位置，
		计算和再之前的位置的欧拉距离，距离太小并且cloudKeyPoses3D不为空(初始化时为空)，则结束；
	2. 如果是刚刚初始化，cloudKeyPoses3D为空，
		那么NonlinearFactorGraph增加一个PriorFactor因子，
		initialEstimate的数据类型是Values（其实就是一个map），这里在0对应的值下面保存一个Pose3，
		本次的transformTobeMapped参数保存到transformLast中去。
	3. 如果本次不是刚刚初始化，从transformLast得到上一次位姿，
    	从transformAftMapped得到本次位姿，
		gtSAMgraph.add(BetweenFactor),到它的约束中去，
    	initialEstimate.insert(序号，位姿)。
	4. 不管是否是初始化，都进行优化，isam->update(gtSAMgraph, initialEstimate);
		得到优化的结果：latestEstimate = isamCurrentEstimate.at<Pose3>(isamCurrentEstimate.size()-1),
		将结果保存，cloudKeyPoses3D->push_back(thisPose3D);
		cloudKeyPoses6D->push_back(thisPose6D);
	5. 对transformAftMapped进行更新;
	6. 最后保存最终的结果：
		cornerCloudKeyFrames.push_back(thisCornerKeyFrame);
    	surfCloudKeyFrames.push_back(thisSurfKeyFrame);
    	outlierCloudKeyFrames.push_back(thisOutlierKeyFrame);
}
```

---
关于`Rot3`和`Point3`和`Pose3`:

>static Rot3 	RzRyRx (double x, double y, double z),Rotations around Z, Y, then X axes;
>
>源码里面RzRyRx依次按照z(transformTobeMapped[2])，y(transformTobeMapped[0])，x(transformTobeMapped[1])坐标轴旋转
>
>Point3 (double x, double y, double z)  Construct from x(transformTobeMapped[5]), y(transformTobeMapped[3]), and z(transformTobeMapped[4]) coordinates.
> 
Pose3 (const Rot3 &R, const Point3 &t) Construct from R,t. 从旋转和平移构造姿态


---

关于`gtsam::ISAM2::update`函数原型:


>ISAM2Result gtsam::ISAM2::update (const NonlinearFactorGraph & 	newFactors = NonlinearFactorGraph(),
>const Values & 	newTheta = Values(),
>const std::vector< size_t > & 	removeFactorIndices = std::vector<size_t>(),
>const boost::optional< FastMap< Key, int > > & 	constrainedKeys = boost::none,
>const boost::optional< FastList< Key > > & 	noRelinKeys = boost::none,
>const boost::optional< FastList< Key > > & 	extraReelimKeys = boost::none,
>bool 	force_relinearize = false )	


在源码中，有对update的调用：
>```
>// gtSAMgraph是新加到系统中的因子
>// initialEstimate是加到系统中的新变量的初始点
>isam->update(gtSAMgraph, initialEstimate);
>````

---

### correctPoses
`void correctPoses()`的调用只在回环结束时进行(`aLoopIsClosed == true`)
校正位姿的过程主要是将`isamCurrentEstimate`的x，y，z平移坐标更新到`cloudKeyPoses3D`中，另外还需要更新`cloudKeyPoses6D`的姿态角。

关于`isamCurrentEstimate`：
`isamCurrentEstimate`是gtsam库中的Values类，Values类的[定义]("http://borg.cc.gatech.edu/sites/edu.borg/html/a00261.html" "A values structure is a map from keys to values.")：
>A values structure is a map from keys to values. It is used to specify the value of a bunch of variables in a factor graph.


在`saveKeyFramesAndFactor()`函数中的更新过程：
>```
>isamCurrentEstimate = isam->calculateEstimate();
>```

---
### publishTF
`void publishTF()`是进行发布坐标变换信息的函数。
发布的消息类型是`nav_msgs::Odometry`,关于`nav_msgs::Odometry`，可以参考它的[定义]("http://docs.ros.org/jade/api/nav_msgs/html/msg/Odometry.html" "ROS官方文档")。

>官方文档中提示需要注意的是：
>`pose`需要声明为`header.frame_id`的坐标系下;
>`twist`需要声明为`child_frame_id`的坐标系下;


```cpp
odomAftMapped.header.frame_id = "/camera_init";
odomAftMapped.child_frame_id = "/aft_mapped";

aftMappedTrans.frame_id_ = "/camera_init";
aftMappedTrans.child_frame_id_ = "/aft_mapped";
```

`publishTF()`中发布里程计信息是3个部分：
```
1. 发布transformAftMapped的信息到"/camera_init"这个frame下面；
2. 发布transformBefMapped的信息到"/aft_mapped"这个frame下面；
3. 发布 tf::StampedTransform aftMappedTrans作为一个姿态变换；
```
---

关于`nav_msgs::Odometry`数据格式的具体定义：

>```cpp
>std_msgs/Header header
>string child_frame_id
>geometry_msgs/PoseWithCovariance pose
>geometry_msgs/TwistWithCovariance twist
>```

上面`std_msgs/Header header`的定义：
>```
>uint32 seq         // 连续增加的ID
>time stamp         // 时间戳有两个整形变量，stamp.sec代表秒，stamp.nsec表示纳秒
>string frame_id    // 0: no frame，1: global frame
>```

`geometry_msgs/PoseWithCovariance`的定义：
>```
>geometry_msgs/Pose pose
>float64[36] covariance   // 6x6协方差的行主表示
>```

>```
>上面pose的定义：
>geometry_msgs/Point position         // 位置
>geometry_msgs/Quaternion orientation // 方向
>
>```

`geometry_msgs/TwistWithCovariance twist`的定义：
>```cpp
>geometry_msgs/Twist twist
>float64[36] covariance
>```

>```
>上面twist的定义：
>geometry_msgs/Vector3 linear   // 线速度向量
>geometry_msgs/Vector3 angular  // 角速度向量
>```


---

### publishKeyPosesAndFrames
`publishKeyPosesAndFrames()`代码很短也很简单。
如果有节点订阅`"/key_pose_origin"`这个话题，则用`pubKeyPoses`发布`cloudKeyPoses3D`；
如果有节点订阅`"/recent_cloud"`这个话题，则用`pubRecentKeyFrames`发布`laserCloudSurfFromMapDS`；


---

### clearCloud
`clearCloud()`很简单，一共四条语句，代码如下：
```cpp
void clearCloud(){
    laserCloudCornerFromMap->clear();
    laserCloudSurfFromMap->clear();
    laserCloudCornerFromMapDS->clear();
    laserCloudSurfFromMapDS->clear();   
}
```

---


### cornerOptimization
函数` void cornerOptimization(int)`基本都是数学公式转化成代码。
该函数分成了几个部分：

1. 进行坐标变换,转换到全局坐标中去；      
2. 进行5邻域搜索，得到结果后对搜索得到的5点求平均值；      
3. 求矩阵matA1=[ax,ay,az]t*[ax,ay,az]，例如ax代表的是x-cx,表示均值与每个实际值的差值，求取5个之后再次取平均，得到matA1；      
4. 求正交阵的特征值和特征向量，特征值：matD1，特征向量：保存在矩阵`matV1`中。      

关于求特征值的函数cv::eigen，可以参考[opencv官方文档](https://docs.opencv.org/ref/master/d2/de8/group__core__array.html#ga9fa0d58657f60eaa6c71f6fbb40456e3 "doc.opencv.org"):      
>**src**	input matrix that must have CV_32FC1 or CV_64FC1 type, square size and be symmetrical (src ^T^ == src).
>**eigenvalues**	output vector of eigenvalues of the same type as src; the eigenvalues are ***stored in the descending order***.
>**eigenvectors**	output matrix of eigenvectors; it has the same size and type as src; the eigenvectors are stored as subsequent matrix rows, in the same order as the corresponding eigenvalues.

因为求取的特征值是按照降序排列的，所以根据论文里面提到的：      
**1.如果这是一个边缘特征，则它的一个特征值远大于其余两个；**      
**2.如果这是一个平面特征，那么其中一个特征值远小于其余两个特征值；**      
根据上面两个原则进行判断要不要进行优化。      
如果没有满足**条件1**，就不进行优化过程，因为这不是一个边缘特征。

5. 如果进行优化，进行优化的过程是这样的：
先定义3组变量，
```cpp
float x0 = pointSel.x;
float y0 = pointSel.y;
float z0 = pointSel.z;
float x1 = cx + 0.1 * matV1.at<float>(0, 0);
float y1 = cy + 0.1 * matV1.at<float>(0, 1);
float z1 = cz + 0.1 * matV1.at<float>(0, 2);
float x2 = cx - 0.1 * matV1.at<float>(0, 0);
float y2 = cy - 0.1 * matV1.at<float>(0, 1);
float z2 = cz - 0.1 * matV1.at<float>(0, 2);
```
然后求`[(x0-x1),(y0-y1),(z0-z1)]`与`[(x0-x2),(y0-y2),(z0-z2)]`叉乘得到的向量的模长,即[XXX,YYY,ZZZ]=[(y0-y1)(z0-z2)-(y0-y2)(z0-z1),-(x0-x1)(z0-z2)+(x0-x2)(z0-z1),(x0-x1)(y0-y2)-(x0-x2)(y0-y1)]的模长。
接着：
```
// l12表示的是0.2*(||V1[0]||)
float l12 = sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2) + (z1 - z2)*(z1 - z2));
```
最后再求一次叉乘：
```
// 求叉乘结果[la',lb',lc']=[(x1-x2),(y1-y2),(z1-z2)]x[XXX,YYY,ZZZ]
// [la,lb,lc]=[la',lb',lc']/a012/l12
float la =...
float lb =...
float lc =...
float ld2 = a012 / l12;
```
```
float s = 1 - 0.9 * fabs(ld2);
```
程序末尾根据`s`的值来判断是否将点云点放入点云集合`laserCloudOri`以及`coeffSel`中。


***但是关于上述方法的基本原理并没有搞明白。***


---

### surfOptimization
 `void surfOptimization(int)`函数进行面优化，内容和函数`cornerOptimization(int)`的内容基本相同。
步骤如下：
1. 进行坐标变换,转换到全局坐标中去；
2. 进行5邻域搜索，得到结果后判断搜索结果是否满足条件(`pointSearchSqDis[4] < 1.0`)，不满足条件就不需要进行优化；
3. 将搜索结果全部保存到`matA0`中，形成一个5x3的矩阵；
4. 解这个矩阵`cv::solve(matA0, matB0, matX0, cv::DECOMP_QR);`,关于`cv::solve`函数，参考[官网](https://docs.opencv.org/ref/master/d2/de8/group__core__array.html#ga12b43690dbd31fed96f213eefead2373 "opencv官网")。`matB0`是一个5x1的矩阵，需要求解的`matX0`是3x1的矩阵；
```cpp
bool cv::solve	(	
InputArray 	src1,
InputArray 	src2,
OutputArray 	dst,
int 	flags = DECOMP_LU 
)
```
关于参数的解释：
>**src1**	input matrix on the left-hand side of the system.
>**src2**	input matrix on the right-hand side of the system.
>**dst**	output solution.
>**flags**	solution (matrix inversion) method (DecompTypes)

所以函数其实是在求解方程`matA0*matX0=matB0`，最后求得`matX0`。这个公式其实是在求由`matA0`中的点构成的平面的法向量`matX0`。
5. 求解得到的`matX0=[pa,pb,pc,pd]`，对`[pa,pb,pc,pd]`进行单位化，
`matB0=[-1,-1,-1,-1,-1]^t`，关于`matB0`为什么全是-1而不是0的问题：
```cpp
if (fabs(pa * laserCloudSurfFromMapDS->points[pointSearchInd[j]].x +
         pb * laserCloudSurfFromMapDS->points[pointSearchInd[j]].y +
         pc * laserCloudSurfFromMapDS->points[pointSearchInd[j]].z + pd) > 0.2) {
    planeValid = false;
    break;
}
```
因为`pd=1`，所以在求解的时候设置了`matB0`全为-1，这里再次判断求解的方向向量和每个点相乘，最后结果是不是在误差范围内。如果误差太大就不把当前点`pointSel`放到点云中去了。
6. 误差在允许的范围内的话把这个点放到点云`laserCloudOri`中去，把关于误差的系数`coeff`放到`coeffSel`中。


---


### LMOptimization
`bool LMOptimization(int)`函数是代码中最重要的一个函数，实现的功能是列文伯格-马夸尔特优化。
首先是对`laserCloudOri`中数据的处理，将它放到`matA`中，这部分没有搞懂其数学原理（可能是在求雅克比矩阵？）
```cpp
float arx = (crx*sry*srz*pointOri.x + crx*crz*sry*pointOri.y - srx*sry*pointOri.z) * coeff.x
             + (-srx*srz*pointOri.x - crz*srx*pointOri.y - crx*pointOri.z) * coeff.y
             + (crx*cry*srz*pointOri.x + crx*cry*crz*pointOri.y - cry*srx*pointOri.z) * coeff.z;

float ary = ((cry*srx*srz - crz*sry)*pointOri.x 
          + (sry*srz + cry*crz*srx)*pointOri.y + crx*cry*pointOri.z) * coeff.x
          + ((-cry*crz - srx*sry*srz)*pointOri.x 
          + (cry*srz - crz*srx*sry)*pointOri.y - crx*sry*pointOri.z) * coeff.z;

float arz = ((crz*srx*sry - cry*srz)*pointOri.x + (-cry*crz-srx*sry*srz)*pointOri.y)*coeff.x
          + (crx*crz*pointOri.x - crx*srz*pointOri.y) * coeff.y
          + ((sry*srz + cry*crz*srx)*pointOri.x + (crz*sry-cry*srx*srz)*pointOri.y)*coeff.z;
```
求完matA之后，再计算`matAtA`，`matAtB`，`matX`
```
cv::transpose(matA, matAt);
matAtA = matAt * matA;
matAtB = matAt * matB;// matB每个对应点的coeff.intensity = s * pd2(在surfOptimization中和cornerOptimization中有)
cv::solve(matAtA, matAtB, matX, cv::DECOMP_QR);// 求解matAtA*matX=matAtB得到matX
```
根据[官方文档](https://docs.opencv.org/ref/master/d2/de8/group__core__array.html#ga46630ed6c0ea6254a35f447289bd7404 "cv::transpose")，`cv::transpose(matA,matAt)`将矩阵由`matA`转置生成`matAt`。

初次优化时，特征值门限设置为100，小于这个值认为是退化了，修改matX，`matX=matP*matX2`

最后将`matX`作为6个量复制到`transformTobeMapped`中去。
在判断是否是有效的优化时，要求旋转部分的模长大于0.05，平移部分的模长也大于0.05。

*上面的代码并没有完全搞清楚，只是知道了一个大概过程，其中的原理并没有深刻理解*




---


mapOptmization.cpp中还有一些函数在本篇笔记中没有进行说明，但是在[源码](https://github.com/wykxwyc/LeGO-LOAM/blob/master/LeGO-LOAM/src/mapOptmization.cpp "wykxwyc的github")中写了注释。

**(mapOptmization.cpp 完)**

