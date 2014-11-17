---
layout: post
title: Spark Common Issues
categories: 
- spark
tags: [spark]
date: 2014-11-13
---

## 1、WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster ui to ensure that workers are registered and have sufficient memory
当前的集群的可用资源不能满足应用程序所请求的资源。


资源分2类： ``cores`` 和 ``ram``

* **Cores**代表对执行可用的``executor slots``
* **Ram**代表每个Worker上被需要的空闲内存来运行你的``Application``。

解决方法：
应用不要请求多余空闲可用资源的
关闭掉已经执行结束的Application

## 2、Application isn’t using all of the Cores: How to set the Cores used by a Spark App
设置每个App所能获得的core
解决方法：
spark-env.sh里设置spark.deploy.defaultCores
或
spark.cores.max
***
## 3、Spark Executor OOM: How to set Memory Parameters on Spark
1. OOM是内存里堆的东西太多了
  增加job的并行度，即增加job的partition数量，把大数据集切分成更小的数据，可以减少一次性load到内存中的数据量。InputFomart， getSplit来确定。
2. spark.storage.memoryFraction
管理executor中RDD和运行任务时的内存比例，如果shuffle比较小，只需要一点点shuffle memory，那么就调大这个比例。默认是0.6。不能比老年代还要大。大了就是浪费。
3. spark.executor.memory如果还是不行，那么就要加Executor的内存了，改完executor内存后，这个需要重启。
***

## 4、Shark Server/ Long Running Application Metadata Cleanup
Spark程序的元数据是会往内存中无限存储的。spark.cleaner.ttl来防止OOM，主要出现在Spark Steaming和Shark Server里。

```scala
export SPARK_JAVA_OPTS +="-Dspark.kryoserializer.buffer.mb=10 -Dspark.cleaner.ttl=43200"
```

***
## 5、Class Not Found: Classpath Issues
问题1、缺少jar，不在classpath里。
问题2、jar包冲突，同一个jar不同版本。

解决1：
将所有依赖jar都打入到一个fatJar包里，然后手动设置依赖到指定每台机器的DIR。

```scala
val conf = new SparkConf().setAppName(appName).setJars(Seq(System.getProperty("user.dir") + "/target/scala-2.10/sparktest.jar"))
```

解决2：
把所需要的依赖jar包都放到default classpath里，分发到各个worker node上。

## 6、关于性能优化：
> * 第一个是sort-based shuffle。这个功能大大的减少了超大规模作业在shuffle方面的内存占用量，使得我们可以用更多的内存去排序。
* 第二个是新的基于Netty的网络模块取代了原有的NIO网络模块。这个新的模块提高了网络传输的性能，并且脱离JVM的GC自己管理内存，降低了GC频率。
* 第三个是一个独立于Spark executor的external shuffle service。这样子executor在GC的时候其他节点还可以通过这个service来抓取shuffle数据，所以网络传输本身不受到GC的影响。


> 	过去一些的参赛系统软件方面的处理都没有能力达到硬件的瓶颈，甚至对硬件的利用率还不到10%。而这次我们的参赛系统在map期间用满了3GB/s的硬盘带宽，达到了这些虚拟机上八块SSD的瓶颈，在reduce期间网络利用率到了1.1GB/s，接近物理极限。


***
##参考文献：
<a href="http://www.datastax.com/dev/blog/common-spark-troubleshooting" target="_blank">http://www.datastax.com/dev/blog/common-spark-troubleshooting</a>
<a href="http://www.csdn.net/article/2014-11-06/2822505" target="_blank">http://www.csdn.net/article/2014-11-06/2822505</a>
