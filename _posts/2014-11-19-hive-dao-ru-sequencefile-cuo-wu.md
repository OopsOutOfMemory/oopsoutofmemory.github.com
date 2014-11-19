---
layout: post
title: Hive导入sequencefile错误
category: 
- hive
tags: hive
date: 2014-11-19
---


``本地load data到hive表中，可能会由于一些表格式的问题或文本格式问题，导致上传失败。``

总结原因：

### 1. 上传格式和建表格式不匹配
自己上传的为txt文本，而创建表指定的file format 是sequencefile。

```sql
hive> load data local inpath '/home/hadoop/ma_test.txt' into table sep26_ma_deposit_dim;  
Copying data from file:/home/hadoop/ma_test.txt  
Copying file: file:/home/hadoop/ma_test.txt  
Loading data to table dw.sep26_ma_deposit_dim  
Failed with exception Wrong file format. Please check the file's format.  
FAILED: Execution Error, return code 1 from org.apache.hadoop.hive.ql.exec.MoveTask  
```

__思路：__

先导入存为textfile,然后再执行MR，覆写这个表

```sql
hive> create table tempshengli_test (t1 int, t2 int, t3 int, t4 string) row format delimited fields terminated by '\t' stored as textfile;  
OK  
Time taken: 0.256 seconds  
hive> desc tempshengli_test;  
OK  
t1      int  
t2      int  
t3      int  
t4      string  
Time taken: 0.141 seconds  
hive> load data local inpath '/home/hadoop/ma_test.txt' into table tempshengli_test;                                                        
Copying data from file:/home/hadoop/ma_test.txt  
Copying file: file:/home/hadoop/ma_test.txt  
Loading data to table dw.tempshengli_test  
OK  
Time taken: 4.228 seconds  
hive> insert overwrite into table sep26_ma_deposit_dim as select * from tempshengli_test;  
FAILED: Parse Error: line 1:17 cannot recognize input near 'into' 'table' 'sep26_ma_deposit_dim' in destination specification  
  
  
hive> insert overwrite table sep26_ma_deposit_dim select * from tempshengli_test;     
Total MapReduce jobs = 2  
Ended Job = job_201403301416_112745  
16 Rows loaded to sep26_ma_deposit_dim  
OK  
Time taken: 64.341 seconds  
```

```sql
drop table tempshengli_test  
```

### 2.文本格式不匹配
还要注意格式, Unix UTF-8和Windows上的ANSI上传上去不一样。