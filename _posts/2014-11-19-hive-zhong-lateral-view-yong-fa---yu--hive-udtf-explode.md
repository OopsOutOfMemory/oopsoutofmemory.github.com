---
layout: post
title: Hive中Lateral View用法 与 Hive UDTF explode
category: 
- hive
date: 2014-11-19
---


Lateral View是Hive中提供给UDTF的conjunction，它可以解决UDTF不能添加额外的select列的问题。

## 1. Why we need Lateral View？

当我们想对hive表中某一列进行split之后，想对其转换成1 to N的模式，即一行转多列。
hive不允许我们在UDTF函数之外，再添加其它select语句。
如下，我们想将登录某个游戏的用户id放在一个字段user_ids里，对每一行数据用UDTF后输出多行。

```sql
select game_id, explode(split(user_ids,'\\[\\[\\[')) as user_id   from login_game_log  where dt='2014-05-15'   
```

``FAILED: Error in semantic analysis: UDTF's are not supported outside the SELECT clause, nor nested in expressions。``  
提示语法分析错误，UDTF不支持函数之外的select 语句，真无语。。。
如果我们想支持怎么办呢？接下来就是``Lateral View`` 登场的时候了。

## 2. Lateral View explain

### 2.1 单个Lateral View
> Lateral view is used in conjunction with user-defined table generatingfunctions such as explode(). As mentioned in Built-in Table-Generating Functions, a UDTF generates zero or more output rows foreach input row. A lateral view first applies the UDTF to each row of base tableand then joins resulting output rows to the input rows to form a virtual tablehaving the supplied table alias.

解释一下：
``Lateral view`` 其实就是用来和像类似explode这种UDTF函数联用的。lateral view 会将UDTF生成的结果放到一个虚拟表中，然后这个虚拟表会和输入行即每个game_id进行join 来达到连接UDTF外的select字段的目的。


### Lateral View Syntax

```sql
lateralView: LATERAL VIEW udtf(expression) tableAlias AS columnAlias (',' columnAlias)*

fromClause: FROM baseTable (lateralView)*
```

可以看出，可以在2个地方用Lateral view：
1. 在udtf前面用
2. 在from baseTable后面用

__举个例子：__
1. 先创建一个文件，里面2列用\t分割，game_id和user_ids

```sql
hive> create table test_lateral_view_shengli(game_id string,userl_ids string) row format delimited fields terminated by '\t' stored as textfile;  
OK  
Time taken: 2.451 seconds  
hive> load data local inpath '/home/hadoop/test_lateral' into table test_lateral_view_shengli;  
Copying data from file:/home/hadoop/test_lateral  
Copying file: file:/home/hadoop/test_lateral  
Loading data to table dw.test_lateral_view_shengli  
OK  
Time taken: 6.716 seconds  
hive> select * from test_lateral_view_shengli;                                                                                                             
OK  
game101       15358083654[[[ab33787873[[[zjy18052480603[[[shlg1881826[[[lxqab110  
game66       winning1ren[[[13810537508  
game101       hu330602003[[[hu330602004[[[hu330602005[[[15967506560  
```

下面使用lateral_view

```sql
hive> select game_id, user_id    
    > from test_lateral_view_shengli lateral view explode(split(userl_ids,'\\[\\[\\[')) snTable as user_id   
    > ;  
Total MapReduce jobs = 1  
Launching Job 1 out of 1  
Number of reduce tasks is set to 0 since there's no reduce operator  
Starting Job = job_201403301416_445839, Tracking URL = http://10.1.9.10:50030/jobdetails.jsp?jobid=job_201403301416_445839  
Kill Command = /app/home/hadoop/src/hadoop-0.20.2-cdh3u5/bin/../bin/hadoop job  -Dmapred.job.tracker=10.1.9.10:9001 -kill job_201403301416_445839  
2014-05-16 17:39:19,108 Stage-1 map = 0%,  reduce = 0%  
2014-05-16 17:39:28,157 Stage-1 map = 100%,  reduce = 0%  
2014-05-16 17:39:38,830 Stage-1 map = 100%,  reduce = 100%  
Ended Job = job_201403301416_445839  
OK  
game101       hu330602003  
game101       hu330602004  
game101       hu330602005  
game101       15967506560  
game101       15358083654  
game101       ab33787873  
game101       zjy18052480603  
game101       shlg1881826  
game101       lxqab110  
game66       winning1ren  
game66       13810537508  
```

### 2.2 多个Lateral View

From语句后可以跟多个Lateral View。

> A FROM clause can have multiple LATERAL VIEW clauses. Subsequent LATERAL VIEWS can reference columns from any of the tables appearing to the left of the LATERAL VIEW.

__给定数据：__

<div>
<table class="confluenceTable  " style="border-collapse:collapse; margin:0px; color:rgb(51,51,51); font-family:Arial,sans-serif; font-size:14px; line-height:20px">
<tbody>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">Array&lt;int&gt; col1</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">Array&lt;string&gt; col2</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">[1, 2]</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">[a", "b", "c"]</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">[3, 4]</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">[d", "e", "f"]</p>
</td>
</tr>
</tbody>
</table>
转换目标：</div>

__转换目标：__

想同时把第一列和第二列拆开，类似做笛卡尔乘积。

<div>
<table class="confluenceTable  " style="border-collapse:collapse; margin:0px; color:rgb(51,51,51); font-family:Arial,sans-serif; font-size:14px; line-height:20px">
<tbody>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">int myCol1</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">string myCol2</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">1</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"a"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">1</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"b"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">1</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"c"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">2</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"a"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">2</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"b"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">2</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"c"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">3</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"d"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">3</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"e"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">3</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"f"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">4</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"d"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">4</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"e"</p>
</td>
</tr>
<tr>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">4</p>
</td>
<td class="confluenceTd" style="border:1px solid rgb(221,221,221); padding:7px 10px; vertical-align:top">
<p style="margin-top:0px; margin-bottom:0px">"f"</p>
</td>
</tr>
</tbody>
</table>
</div>


我们可以这样写：

```sql
SELECT myCol1, myCol2 FROM baseTable  
LATERAL VIEW explode(col1) myTable1 AS myCol1  
LATERAL VIEW explode(col2) myTable2 AS myCol2;  
```

3. Outer Lateral View
还有一种情况，如果UDTF转换的Array是空的怎么办呢？
在Hive0.12里面会支持outer关键字，如果UDTF的结果是空，默认会被忽略输出。
如果加上outer关键字，则会像left outer join 一样，还是会输出select出的列，而UDTF的输出结果是NULL。

```sql
hive> select * FROM test_lateral_view_shengli LATERAL VIEW explode(array()) C AS a ;  
```

结果是什么都不输出。

如果加上outer关键字：

```sql
SELECT * FROM src LATERAL VIEW OUTER explode(array()) C AS a limit 10;  
```

```
238 val_238 NULL  
86 val_86 NULL  
311 val_311 NULL  
27 val_27 NULL  
165 val_165 NULL  
409 val_409 NULL  
255 val_255 NULL  
278 val_278 NULL  
98 val_98 NULL  
...  
```

## 4.总结：

Lateral View通常和UDTF一起出现，为了解决UDTF不允许在select字段的问题。
Multiple Lateral View可以实现类似笛卡尔乘积。
Outer关键字可以把不输出的UDTF的空结果，输出成NULL，防止丢失数据。
