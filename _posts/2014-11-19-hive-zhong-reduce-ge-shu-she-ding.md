---
layout: post
title: Hive中reduce个数设定
categories:
- hive
tags: [hive, reduce] 
date: 2014-11-19
---

我们每次执行hive的hql时，shell里都会提示一段话：

```scala
...  
Number of reduce tasks not specified. Estimated from input data size: 500  
In order to change the average load for a reducer (in bytes):  
  set hive.exec.reducers.bytes.per.reducer=<number>  
In order to limit the maximum number of reducers:  
  set hive.exec.reducers.max=<number>  
In order to set a constant number of reducers:  
  set mapred.reduce.tasks=<number>  
...  
```

这个是调优的经常手段，主要有一下三个属性来决定

### hive.exec.reducers.bytes.per.reducer  

这个参数控制一个job会有多少个reducer来处理，依据的是输入文件的总大小。默认1GB。

> This controls how many reducers a map-reduce job should have, depending on the total size of input files to the job. Default is 1GB

### hive.exec.reducers.max     

这个参数控制最大的reducer的数量， 如果 input / bytes per reduce > max  则会启动这个参数所指定的reduce个数。  这个并不会影响mapre.reduce.tasks参数的设置。默认的max是999。

> This controls the maximum number of reducers a map-reduce job can have.  If input_file_size divided by "hive.exec.bytes.per.reducer" is greater than this value, the map-reduce job will have this value as the number reducers.  Note this does not affect the number of reducers directly specified by the user through "mapred.reduce.tasks" and query hints

### mapred.reduce.tasks

  这个参数如果指定了，hive就不会用它的estimation函数来自动计算reduce的个数，而是用这个参数来启动reducer。默认是-1.

> This overrides the hadoop configuration to make sure we enable the estimation of the number of reducers by the size of the input files. If this value is non-negative, then hive will pass this number directly to map-reduce jobs instead of doing the estimation.

reduce的个数设置其实对执行效率有很大的影响：
1. 如果reduce太少：  如果数据量很大，会导致这个reduce异常的慢，从而导致这个任务不能结束，也有可能会OOM
2. 如果reduce太多：  产生的小文件太多，合并起来代价太高，namenode的内存占用也会增大。

如果我们不指定``mapred.reduce.tasks``， hive会自动计算需要多少个``reducer``。

计算的公式：  ``reduce个数 =  InputFileSize   /   bytes per reducer``

这个数个粗略的公式，详细的公式在：
``common/src/java/org/apache/hadoop/hive/conf/HiveConf.java``

我们先看下： 
1. 计算输入文件大小的方法：其实很简单，遍历每个路径获取length，累加。

```scala
+   * Calculate the total size of input files.  
+   * @param job the hadoop job conf.  
+   * @return the total size in bytes.  
+   * @throws IOException   
+   */  
+  public static long getTotalInputFileSize(JobConf job, mapredWork work) throws IOException {  
+    long r = 0;  
+    FileSystem fs = FileSystem.get(job);  
+    // For each input path, calculate the total size.  
+    for (String path: work.getPathToAliases().keySet()) {  
+      ContentSummary cs = fs.getContentSummary(new Path(path));  
+      r += cs.getLength();  
+    }  
+    return r;  
+  }  
```

2、估算reducer的个数，及计算公式：
注意最重要的一句话：  int reducers = (int)((totalInputFileSize + bytesPerReducer - 1) / bytesPerReducer);

```scala
+  /**  
+   * Estimate the number of reducers needed for this job, based on job input,  
+   * and configuration parameters.  
+   * @return the number of reducers.  
+   */  
+  public int estimateNumberOfReducers(HiveConf hive, JobConf job, mapredWork work) throws IOException {  
+    long bytesPerReducer = hive.getLongVar(HiveConf.ConfVars.BYTESPERREDUCER);  
+    int maxReducers = hive.getIntVar(HiveConf.ConfVars.MAXREDUCERS);  
+    long totalInputFileSize = getTotalInputFileSize(job, work);  
+  
+    LOG.info("BytesPerReducer=" + bytesPerReducer + " maxReducers=" + maxReducers   
+        + " totalInputFileSize=" + totalInputFileSize);  
+    int reducers = (int)((totalInputFileSize + bytesPerReducer - 1) / bytesPerReducer);  
+    reducers = Math.max(1, reducers);  
+    reducers = Math.min(maxReducers, reducers);  
+    return reducers;      
+  }  
```

3、真正的计算流程代码：

```scala
+  /**  
+   * Set the number of reducers for the mapred work.  
+   */  
+  protected void setNumberOfReducers() throws IOException {  
+    // this is a temporary hack to fix things that are not fixed in the compiler  
+    Integer numReducersFromWork = work.getNumReduceTasks();  
+      
+    if (numReducersFromWork != null && numReducersFromWork >= 0) {  
+      LOG.info("Number of reduce tasks determined at compile: " + work.getNumReduceTasks());  
+    } else if(work.getReducer() == null) {  
+      LOG.info("Number of reduce tasks not specified. Defaulting to 0 since there's no reduce operator");  
+      work.setNumReduceTasks(Integer.valueOf(0));  
+    } else {  
+      int reducers = estimateNumberOfReducers(conf, job, work);  
+      work.setNumReduceTasks(reducers);  
+      LOG.info("Number of reduce tasks not specified. Estimated from input data size: " + reducers);  
     }  
   }  
```

这就是reduce个数计算的原理。

By the way :
今天中午在群里看到一位朋友问到：
> 当前hive的reduce个数的设定是依据map阶段输入的数据量大小来除以每一个reduce能够处理的数据量来决定有多少个的，但是考虑到经过map阶段处理的数据很可能可输入数据相差很大，这样子的话，当初设定的reduce个数感觉不太合理。。。请问hive当前能支持依据map阶段输出数据量的大小决定reduce个数么？（但是，reduce任务的开启是在有某些map任务完成就会开始的，所以要等到所有map全部执行完成再统计数据量来决定reduce个数感觉也不太合理）  有没有什么好方法？谢谢

这个问题的大意是，reducer个数是根据输入文件的大小来估算出来的，但是实际情况下，Map的输出文件才是真正要到reduce上计算的数据量，如何依据Map的阶段输出数据流觉得reduce的个数，才是实际的问题。

__我给出的思路是：__

1. hack下源码，计算下``每个map输出的大小``×``map个数``不就估算出``map总共输出的数据量``了吗？不用等它结束，因为每个map的处理量是一定的。

2. 你把源码的 ``总输入量 / 每个reduce处理量``  改成 ``总输出量`` / ``每个reduce处理量``不就行了？（``总输出=每个Map输出文件的大小×map个数``）

Ps:最后朋友提到：
建议不错，虽然有一定误差。 谢谢。   不过，如果``filter push down``的话，每一个ｍａｐ的输出大小差别可能比较大。。。而且``filter push down``现在应该是hive默认支持的了

大意是，还是会有一些误差，谓词下推可能会影响Map的输出大小。

本文权且当作回顾加备忘，如有不对之处，请高手指正。
—EOF——