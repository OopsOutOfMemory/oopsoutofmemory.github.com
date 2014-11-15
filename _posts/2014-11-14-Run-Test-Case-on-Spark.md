---
layout: post
title: Run Test Case on Spark
category: Spark
date: 2014-11-14
---

今天有哥们问到如何对Spark进行单元测试。现在将Sbt的测试方法写出来，如下：

**对Spark的test case进行测试的时候可以用sbt的test命令：**

## 一、测试全部test case
     sbt/sbt test

## 二、测试单个test case
     sbt/sbt "test-only *DriverSuite*" 

下面举个例子：
这个Test Case是位于
```
$SPARK_HOME/core/src/test/scala/org/apache/spark/DriverSuite.scala 
```

FunSuit是scalatest里面的测试Suit，要继承它。这里主要是一个回归测试，测试Spark程序正常结束后，Driver会不会正常退出。
注：我就拿这个例子模拟一下，测试成功和测试失败的情景，这个例子和DriverSuite的测试目的完全不一致，只是演示作用。 ：）

## 下面是正常运行退出的例子：

```scala
package org.apache.spark

import java.io.File

import org.apache.log4j.Logger
import org.apache.log4j.Level

import org.scalatest.FunSuite
import org.scalatest.concurrent.Timeouts
import org.scalatest.prop.TableDrivenPropertyChecks._
import org.scalatest.time.SpanSugar._

import org.apache.spark.util.Utils

import scala.language.postfixOps

class DriverSuite extends FunSuite with Timeouts {

  test("driver should exit after finishing") {
    val sparkHome = sys.env.get("SPARK_HOME").orElse(sys.props.get("spark.home")).get
    // Regression test for SPARK-530: "Spark driver process doesn't exit after finishing"
    val masters = Table(("master"), ("local"), ("local-cluster[2,1,512]"))
    forAll(masters) { (master: String) =>
      failAfter(60 seconds) {
        Utils.executeAndGetOutput(
          Seq("./bin/spark-class", "org.apache.spark.DriverWithoutCleanup", master),
          new File(sparkHome),
          Map("SPARK_TESTING" -> "1", "SPARK_HOME" -> sparkHome))
      }
    }
  }
}

/**
 * Program that creates a Spark driver but doesn't call SparkContext.stop() or
 * Sys.exit() after finishing.
 */
object DriverWithoutCleanup {
  def main(args: Array[String]) {
    Logger.getRootLogger().setLevel(Level.WARN)
    val sc = new SparkContext(args(0), "DriverWithoutCleanup")
    sc.parallelize(1 to 100, 4).count()
  }
}
```

executeAndGetOutput方法接受一个command命令，调用spark-class来运行DriverWithoutCleanup类。

```scala
 /**
   * Execute a command and get its output, throwing an exception if it yields a code other than 0.
   */
  def executeAndGetOutput(command: Seq[String], workingDir: File = new File("."),
                          extraEnvironment: Map[String, String] = Map.empty): String = {
    val builder = new ProcessBuilder(command: _*) 
        .directory(workingDir)
    val environment = builder.environment()
    for ((key, value) <- extraEnvironment) {
      environment.put(key, value)
    }
    val process = builder.start()  //启动一个进程来运行spark job
    new Thread("read stderr for " + command(0)) {
      override def run() {
        for (line <- Source.fromInputStream(process.getErrorStream).getLines) {
          System.err.println(line)
        }
      }
    }.start()
    val output = new StringBuffer
    val stdoutThread = new Thread("read stdout for " + command(0)) { //读取spark job的输出
      override def run() {
        for (line <- Source.fromInputStream(process.getInputStream).getLines) {
          output.append(line)
        }
      }
    }
    stdoutThread.start()
    val exitCode = process.waitFor()
    stdoutThread.join()   // Wait for it to finish reading output
    if (exitCode != 0) {
      throw new SparkException("Process " + command + " exited with code " + exitCode)
    }
    output.toString //返回spark job的输出
  }
```

运行第二个命令可以看到运行结果：
```sbt/sbt "test-only *DriverSuite*" ```
执行结果：   

```scala
[info] Compiling 1 Scala source to /app/hadoop/spark-1.0.1/core/target/scala-2.10/test-classes...
[info] DriverSuite: //执行DriverSuit这个TestSuit
Spark assembly has been built with Hive, including Datanucleus jars on classpath
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/app/hadoop/spark-1.0.1/lib_managed/jars/slf4j-log4j12-1.7.5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/app/hadoop/spark-1.0.1/assembly/target/scala-2.10/spark-assembly-1.0.1-hadoop0.20.2-cdh3u5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]
14/08/14 18:20:15 WARN spark.SparkConf: 
SPARK_CLASSPATH was detected (set to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*').
This is deprecated in Spark 1.0+.

Please instead use:
 - ./spark-submit with --driver-class-path to augment the driver classpath
 - spark.executor.extraClassPath to augment the executor classpath
        
14/08/14 18:20:15 WARN spark.SparkConf: Setting 'spark.executor.extraClassPath' to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*' as a work-around.
14/08/14 18:20:15 WARN spark.SparkConf: Setting 'spark.driver.extraClassPath' to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*' as a work-around.
Spark assembly has been built with Hive, including Datanucleus jars on classpath
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/app/hadoop/spark-1.0.1/lib_managed/jars/slf4j-log4j12-1.7.5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/app/hadoop/spark-1.0.1/assembly/target/scala-2.10/spark-assembly-1.0.1-hadoop0.20.2-cdh3u5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]
14/08/14 18:20:19 WARN spark.SparkConf: 
SPARK_CLASSPATH was detected (set to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*').
This is deprecated in Spark 1.0+.

Please instead use:
 - ./spark-submit with --driver-class-path to augment the driver classpath
 - spark.executor.extraClassPath to augment the executor classpath
        
14/08/14 18:20:19 WARN spark.SparkConf: Setting 'spark.executor.extraClassPath' to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*' as a work-around.
14/08/14 18:20:19 WARN spark.SparkConf: Setting 'spark.driver.extraClassPath' to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*' as a work-around.
Spark assembly has been built with Hive, including Datanucleus jars on classpath
Spark assembly has been built with Hive, including Datanucleus jars on classpath
[info] - driver should exit after finishing
[info] ScalaTest
[info] Run completed in 12 seconds, 586 milliseconds.
[info] Total number of tests run: 1
[info] Suites: completed 1, aborted 0
[info] Tests: succeeded 1, failed 0, canceled 0, ignored 0, pending 0
[info] All tests passed.
[info] Passed: Total 1, Failed 0, Errors 0, Passed 1
[success] Total time: 76 s, completed Aug 14, 2014 6:20:26 PM
```

测试通过:
``Total 1， Failed 0， Errors 0， Passed 1。``
这里如果我们稍微将test case 改改，让spark job抛异常，那么这个，这样test case 就会failed掉，如下：

```scala
object DriverWithoutCleanup {
  def main(args: Array[String]) {
    Logger.getRootLogger().setLevel(Level.WARN)
    val sc = new SparkContext(args(0), "DriverWithoutCleanup")
    sc.parallelize(1 to 100, 4).count()
    throw new RuntimeException("OopsOutOfMemory, haha, not real OOM, don't worry!") //添加此行
  }
```

那么，再次运行测试,会发现错误:

```scala
 [info] DriverSuite:
Spark assembly has been built with Hive, including Datanucleus jars on classpath
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/app/hadoop/spark-1.0.1/lib_managed/jars/slf4j-log4j12-1.7.5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/app/hadoop/spark-1.0.1/assembly/target/scala-2.10/spark-assembly-1.0.1-hadoop0.20.2-cdh3u5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]
14/08/14 18:40:07 WARN spark.SparkConf: 
SPARK_CLASSPATH was detected (set to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*').
This is deprecated in Spark 1.0+.

Please instead use:
 - ./spark-submit with --driver-class-path to augment the driver classpath
 - spark.executor.extraClassPath to augment the executor classpath
        
14/08/14 18:40:07 WARN spark.SparkConf: Setting 'spark.executor.extraClassPath' to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*' as a work-around.
14/08/14 18:40:07 WARN spark.SparkConf: Setting 'spark.driver.extraClassPath' to '/home/hadoop/src/hadoop/lib/:/app/hadoop/sparklib/*:/app/hadoop/spark-1.0.1/lib_managed/jars/*' as a work-around.
Exception in thread "main" java.lang.RuntimeException: OopsOutOfMemory, haha, not real OOM, don't worry! //自定义抛异常使spark job运行失败，打印出了异常堆栈，测试用例失败
        at org.apache.spark.DriverWithoutCleanup$.main(DriverSuite.scala:60)
        at org.apache.spark.DriverWithoutCleanup.main(DriverSuite.scala)
[info] - driver should exit after finishing *** FAILED ***
[info]   SparkException was thrown during property evaluation. (DriverSuite.scala:40)
[info]     Message: Process List(./bin/spark-class, org.apache.spark.DriverWithoutCleanup, local) exited with code 1
[info]     Occurred at table row 0 (zero based, not counting headings), which had values (
[info]       master = local
[info]     )
[info] ScalaTest
[info] Run completed in 4 seconds, 765 milliseconds.
[info] Total number of tests run: 1
[info] Suites: completed 1, aborted 0
[info] Tests: succeeded 0, failed 1, canceled 0, ignored 0, pending 0
[info] *** 1 TEST FAILED ***
[error] Failed: Total 1, Failed 1, Errors 0, Passed 0
[error] Failed tests:
[error]         org.apache.spark.DriverSuite
[error] (core/test:testOnly) sbt.TestsFailedException: Tests unsuccessful
[error] Total time: 14 s, completed Aug 14, 2014 6:40:10 PM
```

可以看到TEST FAILED。

##  三、 总结：
  本文主要讲解了，如何运行spark的测试用例，运行全部test case，和运行单个test case的命令，并通过一个例子讲解其运行正常和失败的详细情景，具体细节还需要继续摸索。如果想做contributor，这一关必须过了。