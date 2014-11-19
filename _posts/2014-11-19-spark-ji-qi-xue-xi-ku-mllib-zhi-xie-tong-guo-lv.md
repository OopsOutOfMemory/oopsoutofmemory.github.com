---
layout: post
title: Spark机器学习库mllib之协同过滤
category: 
- Machine Learning
- spark
- mllib
tags: [spark, mllib, 协同过滤]
date: 2014-11-19
---

很久就想写一篇ML的实践文章，虽然看过肯多资料，总觉得纸上谈兵印象不深刻，过不了多久就忘了，现在就借Spark的Mllib来简单的实际一下推荐算法吧。
  
说起推荐算法，大家耳熟能详的就是CF（协同过滤），这次就拿CF中ALS（alternating least squares），交替最小二乘，来做个例子吧。
CF里面的算法比较多，有基于物品的，基于用户的，ALS是基于矩阵分解的，关于对推荐算法的小结，请参考我的推荐算法总结Recommendation

## Mllib

先介绍下``mllib``，mllib是运行在Spark上一个机器学习算法库。借助Spark的内存计算，可以使机器学习的模型计算时间大大缩短。
目前，spark1.0.0中的mllib中已经有很多算法了，具体可以参见官方网站<http://spark.apache.org/docs/latest/mllib-guide.html>
    
我们知道，协同过滤是基于用户行为的一种推荐算法，需要用户对Item的评价。
    于是乎我们还是找到最经典的数据集movielens,地址<http://grouplens.org/datasets/movielens/>

Down下来ml-100k，解压后有很多文件，可以看README里面对数据集的介绍。

```scala
user id | item id | rating | timestamp                
1       1      5       874965758  
1       2      3       876893171  
1       3      4       878542960  
1       4      3       876893119  
1       5      3       889751712  
1       7      4       875071561  
1       8      1       875072484  
1       9      5       878543541  
2       1      2       875072262  
2       3      5       875071805  
2       5      5       875071608  
2       6      5       878543541  
2       8      4       887432020  
2       9      5       875071515  
2       1      1       878542772  
2       2      4       875072404  
```

这里有user对某个movie的评分rating和时间timstamp


先预处理一下数据

```scala
cat u1.base | awk -F "\t" '{print $1"::"$2"::"$3"::"$4}' > ratings.dat  
cat u.item | awk -F "|" '{print $1"\t"$2"\t"$3}' > movies.dat  
数据结果：

```scala
user id::movie id::rating:: timestamp  
1::1::5::874965758  
1::5::3::889751712  
1::7::4::875071561  
1::8::1::875072484  
1::9::5::878543541  
2::258::3::888549961  
2::269::4::888550774  
2::272::5::888979061  
2::273::4::888551647  
2::274::3::888551497  
  
movie id ::movie id :: movie release date  
1::Toy Story (1995)::01-Jan-1995  
2::GoldenEye (1995)::01-Jan-1995  
3::Four Rooms (1995)::01-Jan-1995  
4::Get Shorty (1995)::01-Jan-1995  
5::Copycat (1995)::01-Jan-1995  
6::Shanghai Triad (Yao a yao yao dao waipo qiao) (1995)::01-Jan-1995  
7::Twelve Monkeys (1995)::01-Jan-1995  
8::Babe (1995)::01-Jan-1995  
9::Dead Man Walking (1995)::01-Jan-1995  
10::Richard III (1995)::22-Jan-1996  
11::Seven (Se7en) (1995)::01-Jan-1995  
12::Usual Suspects, The (1995)::14-Aug-1995  
```

OK，下面我们要用官方的ALS算法例子来运行下这个推荐。
首先导入mllib包，我们需要用到ALS算法类和Rating评分类

```scala
import org.apache.spark.mllib.recommendation.ALS  
import org.apache.spark.mllib.recommendation.Rating  

//加载数据  
val data = sc.textFile("/app/hadoop/ml-100k/ratings.dat")  
//data中每条数据经过map的split后会是一个数组，模式匹配后，会new一个Rating对象  
val ratings = data.map(_.split("::") match { case Array(user, item, rate, ts) =>  
    Rating(user.toInt, item.toInt, rate.toDouble)  
  })  

最终会new成对象

```scala
scala> ratings take 2  
......  
14/06/25 17:51:06 INFO scheduler.DAGScheduler: Computing the requested partition locally  
14/06/25 17:51:06 INFO rdd.HadoopRDD: Input split: file:/app/hadoop/ml-100k/ratings.dat:0+1826544  
14/06/25 17:51:07 INFO spark.SparkContext: Job finished: take at <console>:22, took 0.062239021 s  
res0: Array[org.apache.spark.mllib.recommendation.Rating] = Array(Rating(1,1,5.0), Rating(1,2,3.0))  
```

```scala
//设置潜在因子个数为10  
scala> val rank = 10  
rank: Int = 10  
//要迭代计算30次  
scala> val numIterations = 30  
numIterations: Int = 30  
```
接下来调用ALS.train()方法，进行模型训练：

```scala
val model = ALS.train(ratings, rank, numIterations, 0.01)  
14/06/25 17:53:04 INFO storage.MemoryStore: ensureFreeSpace(200) called with curMem=84002, maxMem=308713881  
14/06/25 17:53:04 INFO storage.MemoryStore: Block broadcast_60 stored as values to memory (estimated size 200.0 B, free 294.3 MB)  
model: org.apache.spark.mllib.recommendation.MatrixFactorizationModel = org.apache.spark.mllib.recommendation.MatrixFactorizationModel@17596ee0  
```
训练完后，我们要对比一下预测的结果，我们那训练集当作测试集，来进行对比测试：

```scala
scala> val usersProducts = ratings.map { case Rating(user, product, rate) =>  
     |   (user, product)  
     | }  
usersProducts: org.apache.spark.rdd.RDD[(Int, Int)] = MappedRDD[623] at map at <console>:21  

```
```scala
//预测后的用户，电影，评分  
scala> val predictions =   
     |   model.predict(usersProducts).map { case Rating(user, product, rate) =>   
     |     ((user, product), rate)  
     |   }  
predictions: org.apache.spark.rdd.RDD[((Int, Int), Double)] = MappedRDD[632] at map at <console>:30  
```

我们用均方根误差来评价一个模型的好坏，所以我们要算一下MSE，来判定这个模型的准确率，其值越小说明越准确。

join一下，然后再计算：

```scala
//原始{(用户，电影)，评分} join  预测后的{(用户，电影)，评分}  
val ratesAndPreds = ratings.map { case Rating(user, product, rate) =>   
  ((user, product), rate)  
}.join(predictions)  
```

```scala
ratesAndPreds.collect take 3  
14/06/25 17:59:35 INFO scheduler.TaskSchedulerImpl: Removed TaskSet 632.0, whose tasks have all completed, from pool   
14/06/25 17:59:35 INFO scheduler.DAGScheduler: Stage 632 (collect at <console>:34) finished in 1.906 s  
14/06/25 17:59:35 INFO spark.SparkContext: Job finished: collect at <console>:34, took 1.939437725 s  
res11: Array[((Int, Int), (Double, Double))] = Array(((933,627),(2.0,1.6977799770529198)), ((537,24),(1.0,2.3191609228008327)), ((717,125),(4.0,3.795616142104737)))  
```

join后的结果，就是每个用户对电影的实际打分和预测打分的一个对比，例如：

```scala
(用户，电影)，(原始评分，预测的评分）
(933,627)，(2.0，1.6977799770529198)
(537,24),(1.0, 2.3191609228008327)
(717,125),(4.0,3.795616142104737)
 ......
```

最后计算均方根误差：

```scala
val MSE = ratesAndPreds.map { case ((user, product), (r1, r2)) =>   
 val err = (r1 - r2)  
 err * err  
.mean()  
```


```scala
14/06/25 18:02:28 INFO scheduler.TaskSetManager: Finished TID 79 in 554 ms on localhost (progress: 1/1)  
14/06/25 18:02:28 INFO scheduler.DAGScheduler: Stage 702 (mean at <console>:36) finished in 0.556 s  
14/06/25 18:02:28 INFO scheduler.TaskSchedulerImpl: Removed TaskSet 702.0, whose tasks have all completed, from pool   
14/06/25 18:02:28 INFO spark.SparkContext: Job finished: mean at <console>:36, took 0.585592521 s  
MSE: Double = 0.4254804561682655  
```

顺便提一下预测的API有三个重载，上面用的是第二个：
调用model的API  predict

```scala
scala> model.predict  
                                                                                                                                             
def predict(user: Int, product: Int): Double                                                                                                 
def predict(usersProducts: org.apache.spark.rdd.RDD[(Int, Int)]): org.apache.spark.rdd.RDD[org.apache.spark.mllib.recommendation.Rating]     
def predict(usersProductsJRDD: org.apache.spark.api.java.JavaRDD[Array[Byte]]): org.apache.spark.api.java.JavaRDD[Array[Byte]]          
```

我们也可以传入user id, product id 来与此 某个用户 对某个 电影 的评分

```scala
model.predict(1,2)  
14/06/25 18:17:36 INFO scheduler.TaskSchedulerImpl: Removed TaskSet 963.0, whose tasks have all completed, from pool   
14/06/25 18:17:36 INFO scheduler.DAGScheduler: Stage 963 (lookup at MatrixFactorizationModel.scala:46) finished in 0.035 s  
14/06/25 18:17:36 INFO spark.SparkContext: Job finished: lookup at MatrixFactorizationModel.scala:46, took 0.066978561 s  
res13: Double = 2.9204503120927363  
```

模型都有了，推荐系统怎么设计就根据实际需求了 ：）

## 总结：

MLlib充分利用了Spark的快速内存计算，迭代效率高的优势，将机器学习的模型计算性能提到另一片天地，这也就是为什么最近Spark备受推崇，那么火的原因。
    目前Mllib的算法库还不是很多，但是Mahout都宣布不接受Mapreduce算法库，都迁移到spark上来了，看来未来机器学习要靠Spark了。至于为什么对于协同过滤先支持的是ALS，也是看中的ALS算法的并行度比较好，在Spark上更能发挥该算法的优势吧。

——EOF——
