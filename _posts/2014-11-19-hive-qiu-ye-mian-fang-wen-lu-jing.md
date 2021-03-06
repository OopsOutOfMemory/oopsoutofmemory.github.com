---
layout: post
title: Hive求页面访问路径
category: 
- hive
tags: [hive, sql]
date: 2014-11-19
---


曾今在论坛上看到一个这样的题：

```sql
SQL的ETL过程，从TRLOG表生成ALLOG表；（结果是一套SQL）
有一张很大的表：TRLOG该表大概有2T左右
TRLOG：
CREATE TABLE TRLOG
(PLATFORM string,
USER_ID int,
CLICK_TIME string,
CLICK_URL string)
row format delimited
fields terminated by '\t';


数据：
PLATFORM USER_ID CLICK_TIME CLICK_URL
WEB 12332321 2013-03-21 13:48:31.324 /home/
WEB 12332321 2013-03-21 13:48:32.954 /selectcat/er/
WEB 12332321 2013-03-21 13:48:46.365 /er/viewad/12.html
WEB 12332321 2013-03-21 13:48:53.651 /er/viewad/13.html
WEB 12332321 2013-03-21 13:49:13.435 /er/viewad/24.html
WEB 12332321 2013-03-21 13:49:35.876 /selectcat/che/
WEB 12332321 2013-03-21 13:49:56.398 /che/viewad/93.html
WEB 12332321 2013-03-21 13:50:03.143 /che/viewad/10.html
WEB 12332321 2013-03-21 13:50:34.265 /home/
WAP 32483923 2013-03-21 23:58:41.123 /m/home/
WAP 32483923 2013-03-21 23:59:16.123 /m/selectcat/fang/
WAP 32483923 2013-03-21 23:59:45.123 /m/fang/33.html
WAP 32483923 2013-03-22 00:00:23.984 /m/fang/54.html
WAP 32483923 2013-03-22 00:00:54.043 /m/selectcat/er/
WAP 32483923 2013-03-22 00:01:16.576 /m/er/49.html
…… …… …… ……


需要把上述数据处理为如下结构的表ALLOG：
CREATE TABLE ALLOG
(PLATFORM string,
USER_ID int,
SEQ int,
FROM_URL string,
TO_URL string)
row format delimited
fields terminated by '\t';


整理后的数据结构：
PLATFORM USER_ID SEQ FROM_URL TO_URL
WEB 12332321 1 NULL /home/
WEB 12332321 2 /home/ /selectcat/er/
WEB 12332321 3 /selectcat/er/ /er/viewad/12.html
WEB 12332321 4 /er/viewad/12.html /er/viewad/13.html
WEB 12332321 5 /er/viewad/13.html /er/viewad/24.html
WEB 12332321 6 /er/viewad/24.html /selectcat/che/
WEB 12332321 7 /selectcat/che/ /che/viewad/93.html
WEB 12332321 8 /che/viewad/93.html /che/viewad/10.html
WEB 12332321 9 /che/viewad/10.html /home/
WAP 32483923 1 NULL /m/home/
WAP 32483923 2 /m/home/ /m/selectcat/fang/
WAP 32483923 3 /m/selectcat/fang/ /m/fang/33.html
WAP 32483923 4 /m/fang/33.html /m/fang/54.html
WAP 32483923 5 /m/fang/54.html /m/selectcat/er/
WAP 32483923 6 /m/selectcat/er/ /m/er/49.html
…… …… …… ……
PLATFORM和USER_ID还是代表平台和用户ID；SEQ字段代表用户按时间排序后的访问顺序，FROM_URL和TO_URL分别代表用户从哪一页跳转到哪一页。对于某个平台上某个用户的第一条访问记录，其FROM_URL是NULL（空值）。
```


说需要用两种办法做出来：
> 1. 实现一个能加速上述处理过程的Hive Generic UDF，并给出使用此UDF实现ETL过程的Hive SQL
2. 实现基于纯Hive SQL的ETL过程，从TRLOG表生成ALLOG表；（结果是一套SQL）


鄙人不才，给出大致思路，以后有时间再补上详细结果：

__大致思路：__

1. 第一个要写个UDAF，group by之后，每个分组排序，排序后，from_url取上一条记录，to取本条记录的url。
2. 第二个先按来distribute by PLATFORM USER_ID sort by CLICK_TIME. 然后row_number编号为seq，这是第一个子查询a，这个子查询a自身Join on  seq_id = seq_id -1 就行了。