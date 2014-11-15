---
layout: post
title: Scala eclipse sbt 应用程序开发
category: Spark
date: 2014-11-14
---

由于Scala有一个比较完备的Eclipse IDE（Scala IDE for Eclipse）, 对于不想从eclipse迁移到Iea平台的Dev来说，如何方便、快速、有效得在Eclipse下编译打包开发Scala应用程序尤为重要。Sbt是类似Maven的一个构建工具，我们将使用它来构建发布程序。

本文会介绍搭建Eclipse开发Scala应用程序的一般步骤，并结合实例演示sbt工具在eclipse里是如何创建项目文件，和编译打包部署程序的。   
这里做个备忘，也为初学者少走弯路而做出点小小的贡献。

---

## 一、环境准备：
   1. Scala : <http://www.scala-lang.org/>
   2. Scala IDE for Eclipse : <http://scala-ide.org/>
   3. Sbt: <http://www.scala-sbt.org//>
   4. Sbt Eclipse : <https://github.com/typesafehub/sbteclipse/>  typesafe的一个sbt for eclipse的助手，可以帮助生成eclipse    
   5. Sbt Assembly ： <https://github.com/sbt/sbt-assembly/> 发布应用程序的一个sbt插件。
   以上列出均为开发时必须的软件环境：我的Scala版本是2.10.3， Sbt版本是0.13

---

## 二、sbt生成scala eclipse项目：
### 目录结构
我们想要在Eclipse里开发scala应用并符合sbt发布程序的文件结构（类似Maven结构），除了手工建立文件结构，还可以采用sbt eclipse的配置方法。  

添加sbt eclipse插件有2种配置方式：

* 一种是在~/.sbt/0.13/plugins//build.sbt 里配置addPlugin,这种做法是全局的插件，即对本机所有sbt项目均使用。
* 另一种是每个项目不一样的plugins，则是在每个项目跟目录下project/plugins.sbt里进行插件配置。

比如test_sbt：

``` scala
victor@victor-ubuntu:~/workspace/test_sbt$ pwd
/home/victor/workspace/test_sbt
```

``` scala
victor-ubuntu:~/workspace/test_sbt$ tree .
.
├── build.sbt
└── project
    └── plugins.sbt

1 directory, 2 files
```

plugins.sbt里面内容配置，添加插件：

```scala
addSbtPlugin("com.typesafe.sbteclipse" % "sbteclipse-plugin" % "2.4.0")
```

### 生成eclipse项目文件
   然后进入到根目录sbt,成功进入sbt，运行eclipse命令生成eclipse的.classpath等eclipse相关文件：

```scala
victor@victor-ubuntu:~/workspace/test_sbt$ ll
total 28
drwxrwxr-x 5 victor victor 4096  8月  4 00:38 ./
drwxrwxr-x 8 victor victor 4096  8月  4 00:28 ../
-rw-rw-r-- 1 victor victor    0  8月  4 00:38 build.sbt
-rw-rw-r-- 1 victor victor  589  8月  4 00:38 .classpath
drwxrwxr-x 4 victor victor 4096  8月  4 00:38 project/
-rw-rw-r-- 1 victor victor  362  8月  4 00:38 .project
drwxrwxr-x 4 victor victor 4096  8月  4 00:38 src/
drwxrwxr-x 4 victor victor 4096  8月  4 00:38 target/
```

可以看到和maven的目录结构是相似的：

``` scala
victor@victor-ubuntu:~/workspace/test_sbt$ tree src
src
├── main
│&nbsp;&nbsp; ├── java
│&nbsp;&nbsp; └── scala
└── test
    ├── java
    └── scala
```

发现没有resouces目录，在根目录的build.sbt里添加：

``
EclipseKeys.createSrc := EclipseCreateSrc.Default + EclipseCreateSrc.Resource
``

再执行sbt eclipse  

```scala 
victor@victor-ubuntu:~/workspace/test_sbt$ tree src/
src/
├── main
│&nbsp;&nbsp; ├── java
│&nbsp;&nbsp; ├── resources
│&nbsp;&nbsp; └── scala
└── test
    ├── java
    ├── resources
    └── scala
```


### 导入Eclipse中
我们进入Eclipse，利用导入向导的import existing project into workspace这一项进行导入。
![image](https://cloud.githubusercontent.com/assets/6489401/5058175/b3ee9cda-6d1f-11e4-9226-af8d3f3d26ae.png)


##   三、开发与部署

至此，我们的项目结构搭建完成，可以像开发java maven项目一样的开发scala sbt项目了。

下面准备用一个实际例子演示在Scala里开发的一般步骤，最近用到scala里的json，就用json4s这个json lib来开发一个解析json的例子，json4s地址：https://github.com/json4s/json4s

### 3.1、添加依赖
我们如果想使用第三方的类，就需要添加依赖关系，和GAV坐标，这个再熟悉不过，我们需要编辑根目录下的build.sbt文件，添加依赖：

这里name,version,scalaVersion要注意每个间隔一行，其它的也是，不然会出错。libraryDependencies是添加依赖的地方：我们添加2个。resolvers是仓库地址，这里配置了多个。
如下：

```scala
name := "shengli_test_sbt"  
  
version := "1.0"  
  
scalaVersion := "2.10.3"  
  
EclipseKeys.createSrc := EclipseCreateSrc.Default + EclipseCreateSrc.Resource  
  
libraryDependencies ++= Seq(  
  "org.json4s" %% "json4s-native" % "3.2.10",  
  "org.json4s" %% "json4s-jackson" % "3.2.10"  
)  
  
resolvers ++= Seq(  
      // HTTPS is unavailable for Maven Central  
      "Maven Repository"     at "http://repo.maven.apache.org/maven2",  
      "Apache Repository"    at "https://repository.apache.org/content/repositories/releases",  
      "JBoss Repository"     at "https://repository.jboss.org/nexus/content/repositories/releases/",  
      "MQTT Repository"      at "https://repo.eclipse.org/content/repositories/paho-releases/",  
      "Cloudera Repository"  at "http://repository.cloudera.com/artifactory/cloudera-repos/",  
      // For Sonatype publishing  
      // "sonatype-snapshots"   at "https://oss.sonatype.org/content/repositories/snapshots",  
      // "sonatype-staging"     at "https://oss.sonatype.org/service/local/staging/deploy/maven2/",  
      // also check the local Maven repository ~/.m2  
      Resolver.mavenLocal  
) 
``` 
再次运行sbt eclipse，则依赖的jar包会自动加载到classpath：

![image](https://cloud.githubusercontent.com/assets/6489401/5058189/880c5570-6d20-11e4-8e99-1c14524d8a57.png)
       
### 3.2、测试程序

一个简单的解析Json的程序，程序很简单，这里就不解释了。

```scala
package com.shengli.json  
import org.json4s._  
import org.json4s.JsonDSL._  
import org.json4s.jackson.JsonMethods._  
  
object JsonSbtTest extends Application{  
      
  
  case class Winner(id: Long, numbers: List[Int])  
  case class Lotto(id: Long, winningNumbers: List[Int], winners: List[Winner], drawDate: Option[java.util.Date])  
  
  val winners = List(Winner(23, List(2, 45, 34, 23, 3, 5)), Winner(54, List(52, 3, 12, 11, 18, 22)))  
  val lotto = Lotto(5, List(2, 45, 34, 23, 7, 5, 3), winners, None)  
  val json =  
    ("lotto" ->  
      ("lotto-id" -> lotto.id) ~   
      ("winning-numbers" -> lotto.winningNumbers) ~  
      ("draw-date" -> lotto.drawDate.map(_.toString)) ~  
      ("winners" ->  
        lotto.winners.map { w =>  
          (("winner-id" -> w.id) ~  
           ("numbers" -> w.numbers))}))  
  
  println(compact(render(json)))  
  println(pretty(render(json)))  
}  
```

至此我们在eclipse能运行Run as Scala Application，但是如何加依赖打包发布呢？

### 3.3、Assembly
还记得Spark里面的assembly吗？那个就是发布用的，sbt本身支持的clean compile package之类的命令，但是带依赖的one jar打包方式还是assembly比较成熟。
Sbt本身的命令：参考<http://www.scala-sbt.org/0.13/tutorial/Running.html> 和<http://www.scala-sbt.org/0.13/docs/Command-Line-Reference.html>

<table>
<tbody>
<tr>
<td><tt>clean</tt></td>
<td>Deletes all generated files (in the <tt>target</tt> directory).</td>
</tr>
<tr>
<td><tt>compile</tt></td>
<td>Compiles the main sources (in <tt>src/main/scala</tt> and <tt>src/main/java</tt> directories).</td>
</tr>
<tr>
<td><tt>test</tt></td>
<td>Compiles and runs all tests.</td>
</tr>
<tr>
<td><tt>console</tt></td>
<td>Starts the Scala interpreter with a classpath including the compiled sources and all dependencies. To return to sbt, type<tt>:quit</tt>, Ctrl+D (Unix), or Ctrl+Z (Windows).</td>
</tr>
<tr>
<td><nobr><tt>run &lt;argument&gt;*</tt></nobr></td>
<td>Runs the main class for the project in the same virtual machine as sbt.</td>
</tr>
<tr>
<td><tt>package</tt></td>
<td>Creates a jar file containing the files in <tt>src/main/resources</tt> and the classes compiled from<tt>src/main/scala</tt> and<tt>src/main/java</tt>.</td>
</tr>
<tr>
<td><tt>help &lt;command&gt;</tt></td>
<td>Displays detailed help for the specified command. If no command is provided, displays brief descriptions of all commands.</td>
</tr>
<tr>
<td><tt>reload</tt></td>
<td>Reloads the build definition (<tt>build.sbt</tt>, <tt>project/*.scala</tt>, <tt>
project/*.sbt</tt> files). Needed if you change the build definition.</td>
</tr>
</tbody>
</table>


``Assembly：``

Assembly是作为一种插件的，所以要在project下面的plugins.sbt里面配置，至此plugins.sbt文件里内容如下：

```scala
resolvers += Resolver.url("artifactory", url("http://scalasbt.artifactoryonline.com/scalasbt/sbt-plugin-releases"))(Resolver.ivyStylePatterns)  
  
resolvers += "Typesafe Repository" at "http://repo.typesafe.com/typesafe/releases/"  
  
addSbtPlugin("com.typesafe.sbteclipse" % "sbteclipse-plugin" % "2.4.0")  
  
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.11.2")  
```

除了插件的配置之外，还需要配置跟目录下build.sbt，支持assembly，在文件头部加入：

```scala
import AssemblyKeys._  
assemblySettings  
   至此build.sbt文件内容如下：
[java] view plaincopy
import AssemblyKeys._  
assemblySettings  
  
name := "shengli_test_sbt"  
  
version := "1.0"  
  
scalaVersion := "2.10.3"  
  
EclipseKeys.createSrc := EclipseCreateSrc.Default + EclipseCreateSrc.Resource  
  
libraryDependencies ++= Seq(  
  "org.json4s" %% "json4s-native" % "3.2.10",  
  "org.json4s" %% "json4s-jackson" % "3.2.10"  
)  
  
resolvers ++= Seq(  
      // HTTPS is unavailable for Maven Central  
      "Maven Repository"     at "http://repo.maven.apache.org/maven2",  
      "Apache Repository"    at "https://repository.apache.org/content/repositories/releases",  
      "JBoss Repository"     at "https://repository.jboss.org/nexus/content/repositories/releases/",  
      "MQTT Repository"      at "https://repo.eclipse.org/content/repositories/paho-releases/",  
      "Cloudera Repository"  at "http://repository.cloudera.com/artifactory/cloudera-repos/",  
      // For Sonatype publishing  
      // "sonatype-snapshots"   at "https://oss.sonatype.org/content/repositories/snapshots",  
      // "sonatype-staging"     at "https://oss.sonatype.org/service/local/staging/deploy/maven2/",  
      // also check the local Maven repository ~/.m2  
      Resolver.mavenLocal  
)  
```
运行sbt assembly命令进行发布：

```scala
> assembly  
[info] Updating {file:/home/victor/workspace/test_sbt/}test_sbt...  
[info] Resolving org.fusesource.jansi#jansi;1.4 ...  
[info] Done updating.  
[info] Compiling 1 Scala source to /home/victor/workspace/test_sbt/target/scala-2.10/classes...  
[warn] there were 1 deprecation warning(s); re-run with -deprecation for details  
[warn] one warning found  
[info] Including: scala-compiler-2.10.0.jar  
[info] Including: scala-library-2.10.3.jar  
[info] Including: json4s-native_2.10-3.2.10.jar  
[info] Including: json4s-core_2.10-3.2.10.jar  
[info] Including: json4s-ast_2.10-3.2.10.jar  
[info] Including: paranamer-2.6.jar  
[info] Including: scalap-2.10.0.jar  
[info] Including: jackson-databind-2.3.1.jar  
[info] Including: scala-reflect-2.10.0.jar  
[info] Including: jackson-annotations-2.3.0.jar  
[info] Including: json4s-jackson_2.10-3.2.10.jar  
[info] Including: jackson-core-2.3.1.jar  
[info] Checking every *.class/*.jar file's SHA-1.  
[info] Merging files...  
[warn] Merging 'META-INF/NOTICE' with strategy 'rename'  
[warn] Merging 'META-INF/LICENSE' with strategy 'rename'  
[warn] Merging 'META-INF/MANIFEST.MF' with strategy 'discard'  
[warn] Merging 'rootdoc.txt' with strategy 'concat'  
[warn] Strategy 'concat' was applied to a file  
[warn] Strategy 'discard' was applied to a file  
[warn] Strategy 'rename' was applied to 2 files  
[info] SHA-1: d4e76d7b55548fb2a6819f2b94e37daea9421684  
[info] Packaging /home/victor/workspace/test_sbt/target/scala-2.10/shengli_test_sbt-assembly-1.0.jar ...  
[info] Done packaging.  
[success] Total time: 39 s, completed Aug 4, 2014 1:26:11 AM 
``` 
我们发现文件发布到了/home/victor/workspace/test_sbt/target/scala-2.10/shengli_test_sbt-assembly-1.0.jar
  
那我们来执行一下，看是否成功：
执行：

```scala
java -cp /home/victor/workspace/test_sbt/target/scala-2.10/shengli_test_sbt-assembly-1.0.jar com.shengli.json.JsonSbtTest
[java] view plaincopy
victor@victor-ubuntu:~/workspace/test_sbt$ java -cp /home/victor/workspace/test_sbt/target/scala-2.10/shengli_test_sbt-assembly-1.0.jar com.shengli.json.JsonSbtTest  
{"lotto":{"lotto-id":5,"winning-numbers":[2,45,34,23,7,5,3],"winners":[{"winner-id":23,"numbers":[2,45,34,23,3,5]},{"winner-id":54,"numbers":[52,3,12,11,18,22]}]}}  
{  
  "lotto" : {  
    "lotto-id" : 5,  
    "winning-numbers" : [ 2, 45, 34, 23, 7, 5, 3 ],  
    "winners" : [ {  
      "winner-id" : 23,  
      "numbers" : [ 2, 45, 34, 23, 3, 5 ]  
    }, {  
      "winner-id" : 54,  
      "numbers" : [ 52, 3, 12, 11, 18, 22 ]  
    } ]  
  }  
}  
```
证实发布的结果是成功的。

## 四、总结
本文介绍了在Eclipse里利用Sbt构建开发Scala程序的一般步骤，并用实例讲解了整个流程。
   用sbt eclipse插件生成sbt文件目录结构，sbt eclipse命令来生成更新jar包依赖。
   用assebly插件对scala应用进行打包发布。   

   
至此，我们的项目结构搭建完成，可以像开发java maven项目一样的开发scala sbt项目了。