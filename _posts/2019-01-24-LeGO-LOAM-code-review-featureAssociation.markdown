---
layout:     post
title:      "LeGO-LOAM 源码阅读笔记(featureAssociation.cpp)"
subtitle:   "Code Review of LeGO-LOAM(featureAssociation.cpp)"
date:       2019-01-24
author:     "wykxwyc"
header-img: "img/post-bg-slam-legoloam.jpg"
tags:
    - SLAM
    - LeGO-LOAM
---

> LeGO-LOAM是一种在LOAM之上进行改进的激光雷达建图方法，建图效果比LOAM要好，但是建图较为稀疏，计算量也更小了。
>
>本文原地址：[wykxwyc的博客](https://wykxwyc.github.io/2019/01/24/LeGO-LOAM-code-review-featureAssociation/)
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

## featureAssociation.cpp
> featureAssociation.cpp顾名思义，进行特征关联的过程。

### FeatureAssociation
FeatureAssociation()构造函数的内容如下：
1. 订阅话题:
	* `"/segmented_cloud"`(`sensor_msgs::PointCloud2`)，数据处理函数[`laserCloudHandler`](#laserCloudHandler)
	* `"/segmented_cloud_info"`(`cloud_msgs::cloud_info`)，数据处理函数[`laserCloudInfoHandler`](#laserCloudInfoHandler)
	* `"/outlier_cloud"`(`sensor_msgs::PointCloud2`)，数据处理函数[`outlierCloudHandler`](#outlierCloudHandler)
	* `imuTopic = "/imu/data"`(`sensor_msgs::Imu`)，数据处理函数[`imuHandler`](#imuHandler)

2. 发布话题，这些topic有：
	* `"/laser_cloud_sharp"`(`sensor_msgs::PointCloud2`)
	* `"/laser_cloud_less_sharp"`(`sensor_msgs::PointCloud2`)
	* `"/laser_cloud_flat"`(`sensor_msgs::PointCloud2`)
	* `"/laser_cloud_less_flat"`(`sensor_msgs::PointCloud2`)
	* `"/laser_cloud_corner_last"`(`sensor_msgs::PointCloud2`)
	* `"/laser_cloud_surf_last"`(`cloud_msgs::cloud_info`)
	* `"/outlier_cloud_last"`(`sensor_msgs::PointCloud2`)
	* `"/laser_odom_to_init"`(`nav_msgs::Odometry`)

然后初始化各类参数。


---

### laserCloudHandler
`laserCloudHandler`修改点云数据的时间戳，将点云数据从ROS定义的格式转化到pcl的格式。


---

### laserCloudInfoHandler
函数比较小:
```cpp
void laserCloudInfoHandler(const cloud_msgs::cloud_infoConstPtr& msgIn)
{
    timeNewSegmentedCloudInfo = msgIn->header.stamp.toSec();
    segInfo = *msgIn;
    newSegmentedCloudInfo = true;
}
```

---


### outlierCloudHandler
```cpp
void outlierCloudHandler(const sensor_msgs::PointCloud2ConstPtr& msgIn){

    timeNewOutlierCloud = msgIn->header.stamp.toSec();

    outlierCloud->clear();
    pcl::fromROSMsg(*msgIn, *outlierCloud);

    newOutlierCloud = true;
}
```

---


### imuHandler
`void imuHandler(const sensor_msgs::Imu::ConstPtr& imuIn)`接触过很多次，因为它就是LOAM代码里的那个。
函数的实现：
1. 通过接收到的imuIn里面的四元素得到roll,pitch,yaw三个角；
2. 对加速度进行坐标变换(`关于坐标变换这一块不够清楚`)；
3. 将欧拉角，加速度，速度保存到循环队列中；
4. 对速度，角速度，加速度进行积分，得到位移，角度和速度(`AccumulateIMUShiftAndRotation()`)；


---


### runFeatureAssociation
`void runFeatureAssociation()`是featureAssociation.cpp中最主要的函数，它调用这个cpp文件中的其他函数。算法步骤如下：
1. 如果有新数据进来则执行，否则不执行任何操作；
2. 将点云数据进行坐标变换，进行插补等工作；
3. 进行光滑性计算，并保存结果；
4. 标记阻塞点；(关于阻塞点没有搞清楚)
5. 特征抽取，然后分别保存到`cornerPointsSharp`等等队列中去；
6. 发布`cornerPointsSharp`等4种类型的点云数据；
7. 预测位姿；
8. 更新变换；
9. 积分总变换；
10. 发布里程计信息及上一次点云信息；

---


### adjustDistortion
`void adjustDistortion()`将点云数据进行坐标变换，进行插补等工作。
1. 对每个点进行处理，首先进行和laboshin_loam代码中的一样的坐标轴变换过程。
```cpp
point.x = segmentedCloud->points[i].y;
point.y = segmentedCloud->points[i].z;
point.z = segmentedCloud->points[i].x;
```
2. 针对每个点计算偏航角yaw，然后根据不同的偏航角，可以知道激光雷达扫过的位置有没有超过一半，计算的时候有一部分需要注意一下：
函数原型：
```
// -atan2(p.x,p.z)==>-atan2(y,x)
// ori表示的是偏航角yaw，因为前面有负号，ori=[-M_PI,M_PI)
// 因为segInfo.orientationDiff表示的范围是(PI,3PI)，在2PI附近
// 下面过程的主要作用是调整ori大小，满足start<ori<end
float ori = -atan2(point.x, point.z);
```
这里分为4种情况：
* 没有转过一半，但是`start-ori>M_PI/2`
* 没有转过一半，但是`ori-start>3/2*M_PI`,说明ori太大，不合理（正常情况在前半圈的话，`ori-start`范围`[0,M_PI]`）
* 转过一半，`end-ori>3/2*PI`,ori太小
* 转过一半，`ori-end>M_PI/2`,太大

3. 然后进行imu数据与激光数据的时间轴对齐操作。
对齐时候有两种情况，一种不能用插补来优化，一种可以通过插补进行优化。
* 不能通过插补进行优化：imu数据比激光数据早，但是没有更后面的数据(打个比方,激光在9点时出现，imu现在只有8点的)
这种情况下while循环是以imuPointerFront == imuPointerLast结束的：
```
// while循环内进行时间轴对齐
while (imuPointerFront != imuPointerLast) {
    if (timeScanCur + pointTime < imuTime[imuPointerFront]) {
        break;
    }
     imuPointerFront = (imuPointerFront + 1) % imuQueLength;
}
```
* 可以通过插补来进行数据的优化：
这种情况只有在imu数据充足的情况下才会发生，
进行插补时，当前timeScanCur + pointTime < imuTime[imuPointerFront]，
而且imuPointerFront是最早一个时间大于timeScanCur + pointTime的imu数据指针。
imuPointerBack是imuPointerFront的前一个imu数据指针。
插补的代码：
```
int imuPointerBack = (imuPointerFront + imuQueLength - 1) % imuQueLength;
float ratioFront = (timeScanCur + pointTime - imuTime[imuPointerBack]) 
                                 / (imuTime[imuPointerFront] - imuTime[imuPointerBack]);
float ratioBack = (imuTime[imuPointerFront] - timeScanCur - pointTime) 
                                / (imuTime[imuPointerFront] - imuTime[imuPointerBack]);
```
通过上面计算的ratioFront以及ratioBack进行插补,
因为imuRollCur和imuPitchCur通常都在0度左右，变化不会很大，因此不需要考虑超过2M_PI的情况,
imuYaw转的角度比较大，需要考虑超过2*M_PI的情况。
```
imuRollCur = imuRoll[imuPointerFront] * ratioFront + imuRoll[imuPointerBack] * ratioBack;
imuPitchCur = imuPitch[imuPointerFront] * ratioFront + imuPitch[imuPointerBack] * ratioBack;
if (imuYaw[imuPointerFront] - imuYaw[imuPointerBack] > M_PI) {
     imuYawCur = imuYaw[imuPointerFront] * ratioFront + (imuYaw[imuPointerBack] + 2 * M_PI) * ratioBack;
} else if (imuYaw[imuPointerFront] - imuYaw[imuPointerBack] < -M_PI) {
     imuYawCur = imuYaw[imuPointerFront] * ratioFront + (imuYaw[imuPointerBack] - 2 * M_PI) * ratioBack;
} else {
     imuYawCur = imuYaw[imuPointerFront] * ratioFront + imuYaw[imuPointerBack] * ratioBack;
}
```
后面再进行imu的速度插补与位置插补。

另外，针对i=0的情况（另一个不同的点云），每次都要用和上面相同的方法判断是否进行插补并且更新imu的数据。
更新的数据用途：后面将速度坐标投影过来会用到i=0时刻的值。

---


### calculateSmoothness
`void calculateSmoothness()`用于计算光滑性，这里的计算没有完全按照公式LOAM论文中的进行。
此处的公式计算中没有除以总点数i及r[i].
注释后的代码如下：
```
void calculateSmoothness()
{
    int cloudSize = segmentedCloud->points.size();
    for (int i = 5; i < cloudSize - 5; i++) {

        float diffRange = segInfo.segmentedCloudRange[i-5] + segInfo.segmentedCloudRange[i-4]
                        + segInfo.segmentedCloudRange[i-3] + segInfo.segmentedCloudRange[i-2]
                        + segInfo.segmentedCloudRange[i-1] - segInfo.segmentedCloudRange[i] * 10
                        + segInfo.segmentedCloudRange[i+1] + segInfo.segmentedCloudRange[i+2]
                        + segInfo.segmentedCloudRange[i+3] + segInfo.segmentedCloudRange[i+4]
                        + segInfo.segmentedCloudRange[i+5];            

        cloudCurvature[i] = diffRange*diffRange;

        // 在markOccludedPoints()函数中对该参数进行重新修改
        cloudNeighborPicked[i] = 0;
		// 在extractFeatures()函数中会对标签进行修改，
		// 初始化为0，surfPointsFlat标记为-1，surfPointsLessFlatScan为不大于0的标签
		// cornerPointsSharp标记为2，cornerPointsLessSharp标记为1
        cloudLabel[i] = 0;

        cloudSmoothness[i].value = cloudCurvature[i];
        cloudSmoothness[i].ind = i;
    }
}

```

---


### markOccludedPoints
`void markOccludedPoints()`选择了距离比较远的那些点，并将他们标记为1，还选择了距离变换大的点，并将他们标记为1。
标记阻塞点??? 阻塞点是哪种点???
函数代码如下：
```
void markOccludedPoints()
{
    int cloudSize = segmentedCloud->points.size();

    for (int i = 5; i < cloudSize - 6; ++i){

        float depth1 = segInfo.segmentedCloudRange[i];
        float depth2 = segInfo.segmentedCloudRange[i+1];
        int columnDiff = std::abs(int(segInfo.segmentedCloudColInd[i+1] - segInfo.segmentedCloudColInd[i]));

        if (columnDiff < 10){

            // 选择距离较远的那些点，并将他们标记为1
            if (depth1 - depth2 > 0.3){
                cloudNeighborPicked[i - 5] = 1;
                cloudNeighborPicked[i - 4] = 1;
                cloudNeighborPicked[i - 3] = 1;
                cloudNeighborPicked[i - 2] = 1;
                cloudNeighborPicked[i - 1] = 1;
                cloudNeighborPicked[i] = 1;
            }else if (depth2 - depth1 > 0.3){
                cloudNeighborPicked[i + 1] = 1;
                cloudNeighborPicked[i + 2] = 1;
                cloudNeighborPicked[i + 3] = 1;
                cloudNeighborPicked[i + 4] = 1;
                cloudNeighborPicked[i + 5] = 1;
                cloudNeighborPicked[i + 6] = 1;
            }
        }

        float diff1 = std::abs(segInfo.segmentedCloudRange[i-1] - segInfo.segmentedCloudRange[i]);
        float diff2 = std::abs(segInfo.segmentedCloudRange[i+1] - segInfo.segmentedCloudRange[i]);

        // 选择距离变化较大的点，并将他们标记为1
        if (diff1 > 0.02 * segInfo.segmentedCloudRange[i] && diff2 > 0.02 * segInfo.segmentedCloudRange[i])
            cloudNeighborPicked[i] = 1;
    }
}
```

---



### extractFeatures
`void extractFeatures()`进行特征抽取，然后分别保存到`cornerPointsSharp`等等队列中去。
保存到不同的队列是不同类型的点云，进行了标记的工作，这一步中减少了点云数量，使计算量减少。
函数首先清空了`cornerPointsSharp`,`cornerPointsLessSharp`,`surfPointsFlat`,`surfPointsLessFlat` 
然后对`cloudSmoothness`队列中`sp`到`ep`之间的点的平滑数据进行从小到大的排列。
然后按照不同的要求，将点的索引放到不同的队列中去。
另外还对点进行了标记。
最后，因为点云太多时，计算量过大，因此需要对点云进行下采样，减少计算量。
代码如下：
```
void extractFeatures()
{
    cornerPointsSharp->clear();
    cornerPointsLessSharp->clear();
    surfPointsFlat->clear();
    surfPointsLessFlat->clear();

    for (int i = 0; i < N_SCAN; i++) {

        surfPointsLessFlatScan->clear();

        for (int j = 0; j < 6; j++) {

            // sp和ep的含义是什么???startPointer,endPointer?
            int sp = (segInfo.startRingIndex[i] * (6 - j)    + segInfo.endRingIndex[i] * j) / 6;
            int ep = (segInfo.startRingIndex[i] * (5 - j)    + segInfo.endRingIndex[i] * (j + 1)) / 6 - 1;

            if (sp >= ep)
                continue;

            // 按照cloudSmoothness.value从小到大排序
            std::sort(cloudSmoothness.begin()+sp, cloudSmoothness.begin()+ep, by_value());

            int largestPickedNum = 0;
            for (int k = ep; k >= sp; k--) {
                // 每次ind的值就是等于k??? 有什么意义?
                // 因为上面对cloudSmoothness进行了一次从小到大排序，所以ind不一定等于k了
                int ind = cloudSmoothness[k].ind;
                if (cloudNeighborPicked[ind] == 0 &&
                    cloudCurvature[ind] > edgeThreshold &&
                    segInfo.segmentedCloudGroundFlag[ind] == false) {
                
                    largestPickedNum++;
                    if (largestPickedNum <= 2) {
                        // 论文中nFe=2,cloudSmoothness已经按照从小到大的顺序排列，
                        // 所以这边只要选择最后两个放进队列即可
                        // cornerPointsSharp标记为2
                        cloudLabel[ind] = 2;
                        cornerPointsSharp->push_back(segmentedCloud->points[ind]);
                        cornerPointsLessSharp->push_back(segmentedCloud->points[ind]);
                    } else if (largestPickedNum <= 20) {
						// 塞20个点到cornerPointsLessSharp中去
						// cornerPointsLessSharp标记为1
                        cloudLabel[ind] = 1;
                        cornerPointsLessSharp->push_back(segmentedCloud->points[ind]);
                    } else {
                        break;
                    }

                    cloudNeighborPicked[ind] = 1;
                    for (int l = 1; l <= 5; l++) {
                        // 从ind+l开始后面5个点，每个点index之间的差值，
                        // 确保columnDiff<=10,然后标记为我们需要的点
                        int columnDiff = std::abs(int(segInfo.segmentedCloudColInd[ind + l] - segInfo.segmentedCloudColInd[ind + l - 1]));
                        if (columnDiff > 10)
                            break;
                        cloudNeighborPicked[ind + l] = 1;
                    }
                    for (int l = -1; l >= -5; l--) {
						// 从ind+l开始前面五个点，计算差值然后标记
                        int columnDiff = std::abs(int(segInfo.segmentedCloudColInd[ind + l] - segInfo.segmentedCloudColInd[ind + l + 1]));
                        if (columnDiff > 10)
                            break;
                        cloudNeighborPicked[ind + l] = 1;
                    }
                }
            }

            int smallestPickedNum = 0;
            for (int k = sp; k <= ep; k++) {
                int ind = cloudSmoothness[k].ind;
                // 平面点只从地面点中进行选择???为什么要这样做???
                if (cloudNeighborPicked[ind] == 0 &&
                    cloudCurvature[ind] < surfThreshold &&
                    segInfo.segmentedCloudGroundFlag[ind] == true) {

                    cloudLabel[ind] = -1;
                    surfPointsFlat->push_back(segmentedCloud->points[ind]);

                    // 论文中nFp=4，将4个最平的平面点放入队列中
                    smallestPickedNum++;
                    if (smallestPickedNum >= 4) {
                        break;
                    }

                    cloudNeighborPicked[ind] = 1;
                    for (int l = 1; l <= 5; l++) {
                        // 从前面往后判断是否是需要的邻接点，是的话就进行标记
                        int columnDiff = std::abs(int(segInfo.segmentedCloudColInd[ind + l] - segInfo.segmentedCloudColInd[ind + l - 1]));
                        if (columnDiff > 10)
                            break;

                        cloudNeighborPicked[ind + l] = 1;
                    }
                    for (int l = -1; l >= -5; l--) {
                        // 从后往前开始标记
                        int columnDiff = std::abs(int(segInfo.segmentedCloudColInd[ind + l] - segInfo.segmentedCloudColInd[ind + l + 1]));
                        if (columnDiff > 10)
                            break;

                        cloudNeighborPicked[ind + l] = 1;
                    }
                }
            }

            for (int k = sp; k <= ep; k++) {
                if (cloudLabel[k] <= 0) {
                    surfPointsLessFlatScan->push_back(segmentedCloud->points[k]);
                }
            }
        }

        // surfPointsLessFlatScan中有过多的点云，如果点云太多，计算量太大
        // 进行下采样，可以大大减少计算量
        surfPointsLessFlatScanDS->clear();
        downSizeFilter.setInputCloud(surfPointsLessFlatScan);
        downSizeFilter.filter(*surfPointsLessFlatScanDS);

        *surfPointsLessFlat += *surfPointsLessFlatScanDS;
    }
}
```

---


### updateTransformation
`void updateTransformation()`中主要是两个部分，一个是找特征平面，通过面之间的对应关系计算出变换矩阵。
另一个部分是通过角、边特征的匹配，计算变换矩阵。
该函数主要由其他四个部分组成：`findCorrespondingSurfFeatures`,`calculateTransformationSurf`
`findCorrespondingCornerFeatures`,`calculateTransformationCorner`
这四个函数分别是对应于寻找对应面、通过面对应计算变换矩阵、寻找对应角/边特征、通过角/边特征计算变换矩阵。
```
void updateTransformation(){

    if (laserCloudCornerLastNum < 10 || laserCloudSurfLastNum < 100)
        return;

    for (int iterCount1 = 0; iterCount1 < 25; iterCount1++) {
        laserCloudOri->clear();
        coeffSel->clear();

        // 找到对应的特征平面
        // 然后计算协方差矩阵，保存在coeffSel队列中
        // laserCloudOri中保存的是对应于coeffSel的未转换到开始时刻的原始点云数据
        findCorrespondingSurfFeatures(iterCount1);

        if (laserCloudOri->points.size() < 10)
            continue;
        // 通过面特征的匹配，计算变换矩阵
        if (calculateTransformationSurf(iterCount1) == false)
            break;
    }

    for (int iterCount2 = 0; iterCount2 < 25; iterCount2++) {

        laserCloudOri->clear();
        coeffSel->clear();

        // 找到对应的特征边/角点
        // 寻找边特征的方法和寻找平面特征的很类似，过程可以参照寻找平面特征的注释
        findCorrespondingCornerFeatures(iterCount2);

        if (laserCloudOri->points.size() < 10)
            continue;
        // 通过角/边特征的匹配，计算变换矩阵
        if (calculateTransformationCorner(iterCount2) == false)
            break;
    }
}
```

---

### integrateTransformation
`void integrateTransformation()`计算了旋转角的累积变化量。
这个函数首先通过`AccumulateRotation()`将局部旋转左边切换至全局旋转坐标。
然后同坐变换转移到世界坐标系下。
再通过`PluginIMURotation(rx, ry, rz, imuPitchStart, imuYawStart, imuRollStart, imuPitchLast, imuYawLast, imuRollLast, rx, ry, rz);`插入imu旋转，更新姿态。

---


featureAssociation.cpp中还有一些函数在本篇笔记中没有进行说明，但是在[源码](https://github.com/wykxwyc/LeGO-LOAM/blob/master/LeGO-LOAM/src/featureAssociation.cpp "wykxwyc的github")中写了注释。

**(featureAssociation.cpp 完)**

***以上是个人对LeGO-LOAM代码的一些笔记，很多都是猜的，不能保证正确***