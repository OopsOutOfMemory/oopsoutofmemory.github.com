---
layout: post
title: Spark Executor Driver资源调度小结
category: 
- spark
tags: [资源调度, spark]
date: 2014-11-19
---

## 一、引子
在Worker Actor中，每次LaunchExecutor会创建一个CoarseGrainedExecutorBackend进程，Executor和CoarseGrainedExecutorBackend是1对1的关系。也就是说集群里启动多少Executor实例就有多少CoarseGrainedExecutorBackend进程。
  那么到底是如何分配Executor的呢？怎么控制调节Executor的个数呢？

## 二、Driver和Executor资源调度

下面主要介绍一下Spark Executor分配策略：

我们仅看，当Application提交注册到Master后，Master会返回RegisteredApplication，之后便会调用schedule（）这个方法，来分配Driver的资源，和启动Executor的资源。
schedule()方法是来调度当前可用资源的调度方法，它管理还在排队等待的Apps资源的分配，这个方法是每次在集群资源发生变动的时候都会调用，根据当前集群最新的资源来进行Apps的资源分配。


__Driver资源调度：__

随机的将Driver分配到空闲的Worker上去，详细流程请看我写的注释 ：）


```scala
// First schedule drivers, they take strict precedence over applications  
val shuffledWorkers = Random.shuffle(workers) // 把当前workers这个HashSet的顺序随机打乱  
for (worker <- shuffledWorkers if worker.state == WorkerState.ALIVE) { //遍历活着的workers  
  for (driver <- waitingDrivers) { //在等待队列中的Driver们会进行资源分配  
    if (worker.memoryFree >= driver.desc.mem && worker.coresFree >= driver.desc.cores) { //当前的worker内存和cpu均大于当前driver请求的mem和cpu，则启动  
      launchDriver(worker, driver) //启动Driver 内部实现是发送启动Driver命令给指定Worker，Worker来启动Driver。  
      waitingDrivers -= driver //把启动过的Driver从队列移除  
    }  
  }  
}  
```

__Executor资源调度：__

Spark默认提供了一种在各个节点进行``round-robin``的调度，用户可以自己设置这个flag

```scala
val spreadOutApps = conf.getBoolean("spark.deploy.spreadOut", true)  
```

在介绍之前我们先介绍一个概念，
``可用的Worker``：什么是可用，可用就是资源空闲足够且满足一定的规则来启动当前App的Executor。

Spark定义了一个canUse方法：这个方法接受一个ApplicationInfo的描述信息和当前Worker的描述信息。
1. 当前worker的空闲内存 比 该app在每个slave要占用的内存 （executor.memory默认512M）大 
2. 当前app从未在此worker启动过App

__总结__： 从这点看出，要满足：该Worker的当前可用最小内存要比配置的executor内存大，并且对于同一个App只能在一个Worker里启动一个Exeutor，如果要启动第二个Executor，那么请到其它Worker里。这样的才算是对App可用的Worker。

```scala
/** 
 * Can an app use the given worker? True if the worker has enough memory and we haven't already 
 * launched an executor for the app on it (right now the standalone backend doesn't like having 
 * two executors on the same worker). 
 */  
def canUse(app: ApplicationInfo, worker: WorkerInfo): Boolean = {  
  worker.memoryFree >= app.desc.memoryPerSlave && !worker.hasExecutor(app)  
}  
```

__SpreadOut分配策略：__

SpreadOut分配策略是一种以round-robin方式遍历集群所有可用Worker，分配Worker资源，来启动创建Executor的策略，好处是尽可能的将cores分配到各个节点，最大化负载均衡和高并行。
下面看看，默认的spreadOutApps模式启动App的过程： 

 1. 等待分配资源的apps队列默认是FIFO的。
 2. app.coresLeft表示的是该app还有cpu资源没申请到：  app.coresLeft  = 当前app申请的maxcpus - granted的cpus
 3. 遍历未分配完全的apps，继续给它们分配资源，
 4. usableWorkers =  从当前ALIVE的Workers中过滤找出上文描述的可用Worker，然后根据cpus的资源空闲，从大到小给Workers排序。
 5. 当toAssign（即将要分配的的core数>0，就找到可以的Worker持续分配）
 6. 当可用Worker的free cores 大于 目前该Worker已经分配的core时，再给它分配1个core，这样分配是很平均的方法。
 7. round-robin轮询可用的Worker循环
 8. toAssign=0时结束循环，开始根据分配策略去真正的启动Executor。

__举例： __

1个APP申请了6个core, 现在有2个Worker可用。
那么： ``toAssign = 6，assigned = 2 ``
那么就会在assigned(1)和assigned(0)中轮询平均分配cores，以+1 core的方式，最终每个Worker分到3个core，即每个Worker的启动一个Executor，每个Executor获得3个cores。

```scala
// Right now this is a very simple FIFO scheduler. We keep trying to fit in the first app  
    // in the queue, then the second app, etc.  
    if (spreadOutApps) {  
      // Try to spread out each app among all the nodes, until it has all its cores  
      for (app <- waitingApps if app.coresLeft > 0) { //对还未被完全分配资源的apps处理  
        val usableWorkers = workers.toArray.filter(_.state == WorkerState.ALIVE)  
          .filter(canUse(app, _)).sortBy(_.coresFree).reverse //根据core Free对可用Worker进行降序排序。  
        val numUsable = usableWorkers.length //可用worker的个数 eg:可用5个worker  
        val assigned = new Array[Int](numUsable) //候选Worker，每个Worker一个下标，是一个数组，初始化默认都是0  
        var toAssign = math.min(app.coresLeft, usableWorkers.map(_.coresFree).sum)//还要分配的cores = 集群中可用Worker的可用cores总和（10）， 当前未分配core（5）中找最小的  
        var pos = 0  
        while (toAssign > 0) {   
          if (usableWorkers(pos).coresFree - assigned(pos) > 0) { //以round robin方式在所有可用Worker里判断当前worker空闲cpu是否大于当前数组已经分配core值  
            toAssign -= 1  
            assigned(pos) += 1 //当前下标pos的Worker分配1个core +1  
          }  
          pos = (pos + 1) % numUsable //round-robin轮询寻找有资源的Worker  
        }  
        // Now that we've decided how many cores to give on each node, let's actually give them  
        for (pos <- 0 until numUsable) {  
          if (assigned(pos) > 0) { //如果assigned数组中的值>0，将启动一个executor在，指定下标的机器上。  
            val exec = app.addExecutor(usableWorkers(pos), assigned(pos)) //更新app里的Executor信息  
            launchExecutor(usableWorkers(pos), exec)  //通知可用Worker去启动Executor  
            app.state = ApplicationState.RUNNING  
          }  
        }  
      }  
    } else {  
```

__非SpreadOut分配策略：__

非SpreadOut策略，该策略：会尽可能的根据每个Worker的剩余资源来启动Executor，这样启动的Executor可能只在集群的一小部分机器的Worker上。这样做对node较少的集群还可以，集群规模大了，Executor的并行度和机器负载均衡就不能够保证了。

当用户设定了参数spark.deploy.spreadOut 为false时，触发此游戏分支偷笑，跑个题，有些困了。。
1. 遍历可用Workers
2. 且遍历Apps
3. 比较当前Worker的可用core和app还需要分配的core，取最小值当做还需要分配的core
4. 如果coreToUse大于0，则直接拿可用的core来启动Executor。。奉献当前Worker全部资源。（Ps：挨个榨干每个Worker的剩余资源。。。。）

__举例__： App申请12个core，3个Worker，Worker1剩余1个core, Worke2r剩7个core, Worker3剩余4个core.

这样会启动3个Executor，Executor1 占用1个core, Executor2占用7个core, Executor3占用4个core.
__总结__：这样是尽可能的满足App，让其尽快执行，而忽略了其并行效率和负载均衡。

```scala
} else {  
     // Pack each app into as few nodes as possible until we've assigned all its cores  
     for (worker <- workers if worker.coresFree > 0 && worker.state == WorkerState.ALIVE) {  
       for (app <- waitingApps if app.coresLeft > 0) {  
         if (canUse(app, worker)) { //直接问当前worker是有空闲的core  
           val coresToUse = math.min(worker.coresFree, app.coresLeft) //有则取，不管多少  
           if (coresToUse > 0) { //有  
             val exec = app.addExecutor(worker, coresToUse) //直接启动  
             launchExecutor(worker, exec)  
             app.state = ApplicationState.RUNNING  
           }  
         }  
       }  
     }  
   }  
 }  
```

## 三、总结：

1. 在Worker Actor中，每次LaunchExecutor会创建一个CoarseGrainedExecutorBackend进程，一个Executor对应一个CoarseGrainedExecutorBackend
2. 针对同一个App，每个Worker里只能有一个针对该App的Executor存在，切记。如果想让整个App的Executor变多，设置SPARK_WORKER_INSTANCES，让Worker变多。
3. Executor的资源分配有2种策略：
  3.1. SpreadOut ：一种以round-robin方式遍历集群所有可用Worker，分配Worker资源，来启动创建Executor的策略，好处是尽可能的将cores分配到各个节点，最大化负载均衡和高并行。
  3.2. 非SpreadOut：会尽可能的根据每个Worker的剩余资源来启动Executor，这样启动的Executor可能只在集群的一小部分机器的Worker上。这样做对node较少的集群还可以，集群规模大了，Executor的并行度和机器负载均衡就不能够保证了。

行文仓促，如有不正之处，请指出，欢迎讨论 ：）


<h2>补充：</h2>
<p>1、关于： &nbsp;<span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(242,242,242)">&nbsp;一个App一个Worker为什么只有允许有针对该App的一个Executor 到底这样设计为何？ 的讨论：</span></p>
<p><a target="_blank" target="_blank" href="http://weibo.com/lianchengzju" title="连城404" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">连城404</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">：Spark是线程级并行模型，为什么需要一个worker为一个app启动多个executor呢？</span><br>
</p>
<p><a target="_blank" target="_blank" href="http://weibo.com/u/3324607202">朴动_zju</a>:一个worker对应一个executorbackend是从mesos那一套迁移过来的，mesos下也是一个slave一个executorbackend。我理解这里是可以实现起多个，但起多个貌&#20284;没什么好处，而且增加了复杂度。<br>
</p>
<p><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)"><a target="_blank" target="_blank" href="http://weibo.com/crazyjvm" style="line-height:21px; text-decoration:none; color:rgb(10,140,210); background-color:rgb(250,250,250)">CrazyJvm</a><a target="_blank" target="_blank" href="http://club.weibo.com/intro" style="line-height:21px; text-decoration:none; color:rgb(10,140,210); background-color:rgb(250,250,250)"><span title="微博达人" class="W_ico16 ico_club" style="display:inline-block; width:14px; height:14px; margin-left:2px; vertical-align:text-bottom"></span></a><a target="_blank" target="_blank" title="微博会员" href="http://vip.weibo.com/personal?from=main" style="line-height:21px; text-decoration:none; color:rgb(10,140,210); background-color:rgb(250,250,250)"><span class="W_ico16 ico_member5" style="display:inline-block; width:16px; height:14px; margin-left:2px; vertical-align:text-bottom"></span></a><span style="line-height:21px; color:rgb(51,51,51); background-color:rgb(250,250,250)">：</span><a target="_blank" target="_blank" href="http://weibo.com/n/CodingCat" style="line-height:21px; text-decoration:none; color:rgb(10,140,210); background-color:rgb(250,250,250)">@CodingCat</a><span style="line-height:21px; color:rgb(51,51,51); background-color:rgb(250,250,250)">&nbsp;做了一个patch可以启动多个，但是还没有被merge。
 从Yarn的角度考虑的话，一个Worker可以对应多个executorbackend，正如一个nodemanager对应多个container。&nbsp;</span><a target="_blank" target="_blank" href="http://weibo.com/n/OopsOutOfMemory" style="line-height:21px; text-decoration:none; color:rgb(10,140,210); background-color:rgb(250,250,250)">@OopsOutOfMemory</a><span style="line-height:21px; color:rgb(51,51,51); background-color:rgb(250,250,250)">&nbsp;</span><br>
</span></p>
<p><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)"><a target="_blank" target="_blank" href="http://weibo.com/oopsoom" title="OopsOutOfMemory" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">OopsOutOfMemory</a><a target="_blank" target="_blank" href="http://club.weibo.com/intro" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)"><span title="微博达人" class="W_ico16 ico_club" style="display:inline-block; width:14px; height:14px; margin-left:2px; vertical-align:text-bottom"></span></a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">：回复</span><a target="_blank" target="_blank" href="http://weibo.com/n/%E8%BF%9E%E5%9F%8E404" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">@连城404</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">:
 如果一个executor太大且装的对象太多，会导致GC很慢，多几个Executor会减少full gc慢的问题。 see this post&nbsp;</span><a target="_blank" target="_blank" title="http://apache-spark-user-list.1001560.n3.nabble.com/executor-cores-vs-num-executors-td9878.html" href="http://t.cn/RP1bVO4" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">http://t.cn/RP1bVO4</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)"></span><span class="S_txt2" style="color:rgb(128,128,128); line-height:21px; background-color:rgb(250,250,250)">(今天
 11:25)</span><br>
</span></p>
<p><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)"><span class="S_txt2" style="color:rgb(128,128,128); line-height:21px; background-color:rgb(250,250,250)"><a target="_blank" target="_blank" href="http://weibo.com/lianchengzju" title="连城404" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">连城404</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">：回复</span><a target="_blank" target="_blank" href="http://weibo.com/n/OopsOutOfMemory" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">@OopsOutOfMemory</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">:哦，这个考虑是有道理的。一个workaround是单台机器部署多个worker，worker相对来说比较廉价。&nbsp;</span></span></span></p>
<p><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)"><span class="S_txt2" style="color:rgb(128,128,128); line-height:21px; background-color:rgb(250,250,250)"><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)"><a target="_blank" target="_blank" href="http://weibo.com/jerrylead" style="text-decoration:none; color:rgb(10,140,210); line-height:21px; background-color:rgb(250,250,250)">JerryLead</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">：回复</span><a target="_blank" target="_blank" href="http://weibo.com/n/OopsOutOfMemory" style="text-decoration:none; color:rgb(10,140,210); line-height:21px; background-color:rgb(250,250,250)">@OopsOutOfMemory</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">:看来都还在变化当中，standalone
 和 YARN 还是有很多不同，我们暂不下结论 (今天 11:35)</span></span></span></span></p>
<p><a target="_blank" target="_blank" href="http://weibo.com/jerrylead" title="JerryLead" style="text-decoration:none; color:rgb(60,166,230); line-height:21px; background-color:rgb(250,250,250)">JerryLead</a><span style="color:rgb(51,51,51); line-height:21px; background-color:rgb(250,250,250)">：问题开始变得复杂了，是提高线程并行度还是提高进程并行度？我想
 Spark 还是优先选择前者，这样 task 好管理，而且 broadcast，cache 的效率高些。后者有一些道理，但参数配置会变得更复杂，各有利弊吧 </span>
<span class="S_txt2" style="color:rgb(128,128,128); line-height:21px; background-color:rgb(250,250,250)">(今天 11:40)</span></p>
<p><br>
</p>
<p>未完待续。。。</p>
<p>传送门：@JerrLead &nbsp;<a target="_blank" href="https://github.com/JerryLead/SparkInternals/blob/master/markdown/1-Overview.md">https://github.com/JerryLead/SparkInternals/blob/master/markdown/1-Overview.md</a></p>
<p><br>
</p>

