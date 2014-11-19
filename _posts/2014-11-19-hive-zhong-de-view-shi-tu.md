---
layout: post
title: Hive中的View视图
category: 
- hive
tags: [sql, hive, view]
date: 2014-11-19
---


> 有一个需求，让找出hive中的所有视图。

但是hive没有直接的命令来查看这个表是否是视图还是普通表。


假设我们看到的用户名和密码是hive_user和123456 

```
cd $HIVE_HOME/conf/
more hive-site.xml
<property>
     <name>javax.jdo.option.ConnectionURL</name>
     <value>jdbc:mysql://host:3306/hive</value>
 </property>
 <property>
     <name>javax.jdo.option.ConnectionDriverName</name>
     <value>com.mysql.jdbc.Driver</value>
 </property>
 <property>
     <name>javax.jdo.option.ConnectionUserName</name>
     <value>hive_user</value>
 </property>
 <property>
     <name>javax.jdo.option.ConnectionPassword</name>
     <value>123456</value>
 </property>
```

查找hive的mmetadata，登录mysql

```sql
mysql -uhive_user -hhost -p123456
```

从TBLS中可以查出哪些表是View视图

```sql
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema | 
| hive               |              
+--------------------+
mysql> show tables;
+-----------------------+
| Tables_in_hive        |
+-----------------------+
| BUCKETING_COLS        | 
| CDS                   | 
| COLUMNS               | 
| COLUMNS_V2            | 
| DATABASE_PARAMS       | 
| DBS                   | 
| DB_PRIVS              | 
| DELETEME1364280120923 | 
| DELETEME1388042180623 | 
| GLOBAL_PRIVS          | 
| GROUPS                | 
| GROUP_DBS             | 
| IDXS                  | 
| INDEX_PARAMS          | 
| PARTITIONS            | 
| PARTITION_KEYS        | 
| PARTITION_KEY_VALS    | 
| PARTITION_PARAMS      | 
| PART_COL_PRIVS        | 
| PART_PRIVS            | 
| ROLES                 | 
| ROLE_MAP              | 
| SDS                   | 
| SD_PARAMS             | 
| SEQUENCE_TABLE        | 
| SERDES                | 
| SERDE_PARAMS          | 
| SORT_COLS             | 
| TABLE_PARAMS          | 
| TBLS                  | 
| TBL_COL_PRIVS         | 
| TBL_PRIVS             | 
| USERS                 | 
| USER_GROUPS           | 
| tbl_with3keys         | 
+-----------------------+
35 rows in set (0.00 sec)
mysql> desc TBLS;
+--------------------+--------------+------+-----+---------+-------+
| Field              | Type         | Null | Key | Default | Extra |
+--------------------+--------------+------+-----+---------+-------+
| TBL_ID             | bigint(20)   | NO   | PRI | NULL    |       | 
| CREATE_TIME        | int(11)      | NO   |     | NULL    |       | 
| DB_ID              | bigint(20)   | YES  | MUL | NULL    |       | 
| LAST_ACCESS_TIME   | int(11)      | NO   |     | NULL    |       | 
| OWNER              | varchar(767) | YES  |     | NULL    |       | 
| RETENTION          | int(11)      | NO   |     | NULL    |       | 
| SD_ID              | bigint(20)   | YES  | MUL | NULL    |       | 
| TBL_NAME           | varchar(128) | YES  | MUL | NULL    |       | 
| TBL_TYPE           | varchar(128) | YES  |     | NULL    |       | 
| VIEW_EXPANDED_TEXT | mediumtext   | YES  |     | NULL    |       | 
| VIEW_ORIGINAL_TEXT | mediumtext   | YES  |     | NULL    |       | 
+--------------------+--------------+------+-----+---------+-------+
```

VIRTUAL_VIEW为我们要查询的视图类型：

```sql
mysql> select TBL_NAME from TBLS where TBL_TYPE='VIRTUAL_VIEW';

```

这样就能找到所有为视图的hive table了。