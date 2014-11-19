---
layout: post
title: Scala的yield
category: 
- scala
tags: [scala]
date: 2014-11-19
---

Scala yield
先看下在Programming scala里yield的定义：

> For each iteration of your for loop, yield generates a value which will be remembered. It's like the for loop has a buffer you can't see, and for each iteration of your for loop, another item is added to that buffer. When your for loop finishes running, it will return this collection of all the yielded values. The type of the collection that is returned is the same type that you were iterating over, so a Map yields a Map, a List yields a List, and so on.

> Also, note that the initial collection is not changed; the for/yield construct creates a new collection according to the algorithm you specify.

大致意思是，每次for循环，yield都会生成一个会被记住的值。就像在循环的时候有一个无形的Buffer，每次迭代，另一个元素就会放入到Buffer里。

当你的循环结束，将会返回被yield的值的一个集合。集合的类型和被迭代的集合类型一样，如果迭代的是list，返回list,如果是map就返回map。。。

REPL 上的yield

```scala
scala> for (i <- 1 to 5) yield i  
res0: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 2, 3, 4, 5)  

[java] view plaincopy
scala> for (i <- 1 until 5) yield i*2  
res3: scala.collection.immutable.IndexedSeq[Int] = Vector(2, 4, 6, 8)  
  
scala> for (i <- 1 until 5) yield i*3  
res4: scala.collection.immutable.IndexedSeq[Int] = Vector(3, 6, 9, 12)  
  
scala> for (i <- 1 until 5) yield i%2  
res5: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 0, 1, 0)  
  
scala> for (i <- 1 to 4) yield i%2  
res6: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 0, 1, 0)  
```

集合上的yeild

```scala
scala> val a = Array(1,2,3,4,5)  
a: Array[Int] = Array(1, 2, 3, 4, 5)  
  
scala> for(e <- a) yield e  
res7: Array[Int] = Array(1, 2, 3, 4, 5)  
```

我们注意到返回的类型是a的类型，即Array[Int]

```scala
scala> val mp = Map("a"->1,"b"->2)  
mp: scala.collection.immutable.Map[java.lang.String,Int] = Map(a -> 1, b -> 2)  
```
```scala
scala> for(m <- mp) yield m  
res12: scala.collection.immutable.Map[java.lang.String,Int] = Map(a -> 1, b -> 2)  
```
```scala
scala> val lst = List(1,3,5,7)  
lst: List[Int] = List(1, 3, 5, 7)  
  
  
scala> for(e <- lst) yield e  
res0: List[Int] = List(1, 3, 5, 7)  
  
  
scala> for(e <- lst) yield e%2  
res1: List[Int] = List(1, 1, 1, 1)  
```

for循环的if和yield

```scala
scala> val lst = List(1,3,5,7)  
lst: List[Int] = List(1, 3, 5, 7) 
```

```scala
  
scala> for(e <- lst if e>3) yield e  
res0: List[Int] = List(5, 7)  
```

```scala
def scalaFiles =  
  for {  
    file <- filesHere  
    if file.isFile  
    if file.getName.endsWith(".scala")  
  } yield file  
```

__yield 关键字的简短总结:__

针对每一次 for 循环的迭代, yield 会产生一个值，被循环记录下来 (内部实现上，像是一个缓冲区).
当循环结束后, 会返回所有 yield 的值组成的集合.
返回集合的类型与被遍历的集合类型是一致的.

用for yield打印一个九九乘法表

```scala
scala> def makeTable() = {  
     |  val table = for(row <- 1 to 9) yield {  
     |      for(col <- 1 until 10) yield {  
     |        val line = (row * col).toString  
     |        val spaces = " " * (4 - line.length)  
     |        (line + spaces).mkString  
     |     }  
     |  }  
     |  table.mkString("\n")  
     | }  
makeTable: ()String  
  
scala> makeTable()  
res1: String =   
Vector(1   , 2   , 3   , 4   , 5   , 6   , 7   , 8   , 9   )  
Vector(2   , 4   , 6   , 8   , 10  , 12  , 14  , 16  , 18  )  
Vector(3   , 6   , 9   , 12  , 15  , 18  , 21  , 24  , 27  )  
Vector(4   , 8   , 12  , 16  , 20  , 24  , 28  , 32  , 36  )  
Vector(5   , 10  , 15  , 20  , 25  , 30  , 35  , 40  , 45  )  
Vector(6   , 12  , 18  , 24  , 30  , 36  , 42  , 48  , 54  )  
Vector(7   , 14  , 21  , 28  , 35  , 42  , 49  , 56  , 63  )  
Vector(8   , 16  , 24  , 32  , 40  , 48  , 56  , 64  , 72  )  
Vector(9   , 18  , 27  , 36  , 45  , 54  , 63  , 72  , 81  )  

```

```scala
scala> def makeRow(row: Int) =     
     |     for(col <- 1 until 10) yield {    
     |         val line = (row * col).toString    
     |         val spaces = " " * (4 - line.length)    
     |         line + spaces    
     |     }    
makeRow: (row: Int)scala.collection.immutable.IndexedSeq[java.lang.String]  
  
  
scala> def multiTable() = {    
     |     val table =     
     |         for(row <- 1 until 10)    
     |             yield makeRow(row).mkString    
     |     table.mkString("\n")    
     | }    
multiTable: ()String  
  
scala> println(multiTable())   
1   2   3   4   5   6   7   8   9     
2   4   6   8   10  12  14  16  18    
3   6   9   12  15  18  21  24  27    
4   8   12  16  20  24  28  32  36    
5   10  15  20  25  30  35  40  45    
6   12  18  24  30  36  42  48  54    
7   14  21  28  35  42  49  56  63    
8   16  24  32  40  48  56  64  72    
9   18  27  36  45  54  63  72  81    
```