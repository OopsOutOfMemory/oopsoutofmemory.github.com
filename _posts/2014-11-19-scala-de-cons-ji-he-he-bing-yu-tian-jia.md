---
layout: post
title: Scala的cons，集合合并与添加
category: 
- scala
tags: [scala]
date: 2014-11-19
---

scala对集合的元素合有特殊的符号，比如::和:::
简单说明一下：
元素和集合连接用::
双冒号是连接 一个元素 和 一个集合

```scala
scala> val furits = "apple"::("orange"::("banana"::Nil))  
furits: List[java.lang.String] = List(apple, orange, banana) 
```

最后的一个Nil代表的是空集合，这个应该都知道
先用一个"banana"元素和Nil一个空集合连接（合并）这时list里只有一个元素
可以看出连接都是在list的头部进行的。
集合和集合连接用:::

```scala
scala> val list1=List(1,2,3)  
list1: List[Int] = List(1, 2, 3)  
  
scala> val list2=List(4,5,6)  
list2: List[Int] = List(4, 5, 6)  
  
scala> list2:::list1  
res55: List[Int] = List(4, 5, 6, 1, 2, 3)  
```

集合和集合连接用cons::

```scala
scala> list2::list1  
res56: List[Any] = List(List(4, 5, 6), 1, 2, 3)
```

这时候有趣的事情出现了，会把list2当成一个元素，即Any类型的放到一个List里，其实这个List[Any]