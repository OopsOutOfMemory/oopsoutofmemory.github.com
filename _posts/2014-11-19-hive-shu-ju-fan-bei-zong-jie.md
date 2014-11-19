---
layout: post
title: Hive数据翻倍总结
category: 
- hive
date: 2014-11-19
---


__问题：__
> 1. 数据源数据重复。。很难发现。。依赖关系。。
2. 本来8千万的数据和8千万的数据一下left outer join后，变成了30亿。。按道理还是8kw。
3. 8千万大表和几十行的小表join，数据严重倾斜，到99.99%就是reduce不完。。最终OOM了。

__总结如下：__

1. 数据源问题：
统计前，首先检查各个数据源表，看是否有重复记录，可能是数据源的问题。

2. 业务原因，手机可能会解绑和重新绑定，所以一个帐号可能对于多个手机，而不是简单的一个帐号和一个手机是一一对应的。

3. join时on的条件不充分，join的时候一定要考虑哪几个条件能唯一的匹配到一条记录，少一个条件，就可能导致笛卡尔乘积。
考虑 on a.id = b.id and  a.sid = b.sid and ？？

__其它总结：__
帐号类型，普通帐号，个性化帐号，手机帐号，邮箱帐号。