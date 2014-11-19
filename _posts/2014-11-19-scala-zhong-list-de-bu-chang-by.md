---
layout: post
title: Scala中List的步长by
category: 
- scala
tags: [scala]
date: 2014-11-19
---

Scala的List不仅可以指定循环区间，而且还能根据步长筛选元素。
List中的步长，by关键字：

```scala
scala> 1 to 100 by 3  
res64: scala.collection.immutable.Range = Range(1, 4, 7, 10, 13, 16, 19, 22, 25,  
 28, 31, 34, 37, 40, 43, 46, 49, 52, 55, 58, 61, 64, 67, 70, 73, 76, 79, 82, 85,  
 88, 91, 94, 97, 100)  
  
scala> 1 to 100 by 2  
res65: scala.collection.immutable.Range = Range(1, 3, 5, 7, 9, 11, 13, 15, 17, 1  
9, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45, 47, 49, 51, 53, 55, 57, 5  
9, 61, 63, 65, 67, 69, 71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93, 95, 97, 9  
9)  
  
scala> 1 to 100 by 1  
res66: scala.collection.immutable.Range = Range(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1  
1, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 3  
1, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 5  
1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 7  
1, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 9  
1, 92, 93, 94, 95, 96, 97, 98, 99, 100)  
```

可以看出，每个元素都相差了by后面的数字个步长

如果我们利用这个求奇数的平方和，1*1+3*3+5*5+ … + 99*99，结果为166650

```scala
scala> List(1 to 100 by 2:_*) map (i=>i*i) sum  
res59: Int = 166650  
```
如果用filter也能做
```scala
scala> (1 to 100) filter (_%2!=0) map (i=>i*i) sum  
res60: Int = 166650  
```

看一下源代码里怎么定义这个by的.

```scala
/** The `Range` class represents integer values in range 
 *  ''[start;end)'' with non-zero step value `step`. 
 *  It's a special case of an indexed sequence. 
 *  For example: 
 * 
 *   
 *     val r1 = 0 until 10 
 *     val r2 = r1.start until r1.end by r1.step + 1 
 *     println(r2.length) // = 5 
 *   
 * 
 *  @param start      the start of this range. 
 *  @param end        the exclusive end of the range. 
 *  @param step       the step for the range. 
 * 
 *  @author Martin Odersky 
 *  @author Paul Phillips 
 *  @version 2.8 
 *  @since   2.5 
 *  @see [[http://docs.scala-lang.org/overviews/collections/concrete-immutable-collection-classes.html#ranges "Scala's Collection Library overview"]] 
 *  section on `Ranges` for more information. 
 * 
 *  @define Coll Range 
 *  @define coll range 
 *  @define mayNotTerminateInf 
 *  @define willNotTerminateInf 
 *  @define doesNotUseBuilders 
 *    '''Note:''' this method does not use builders to construct a new range, 
 *         and its complexity is O(1). 
 */  
@SerialVersionUID(7618862778670199309L)  
class Range(val start: Int, val end: Int, val step: Int)  
extends IndexedSeq[Int]  
   with collection.CustomParallelizable[Int, ParRange]  
   with Serializable  
{  
  override def par = new ParRange(this)  
  
  // This member is designed to enforce conditions:  
  //   (step != 0) && (length <= Int.MaxValue),  
  // but cannot be evaluated eagerly because we have a pattern where ranges  
  // are constructed like:    "x to y by z"  
  // The "x to y" piece should not trigger an exception. So the calculation  
  // is delayed, which means it will not fail fast for those cases where failing  
  // was correct.  
  private lazy val numRangeElements: Int = Range.count(start, end, step, isInclusive)  
  
  protected def copy(start: Int, end: Int, step: Int): Range = new Range(start, end, step)  
  
  /** Create a new range with the `start` and `end` values of this range and 
   *  a new `step`. 
   * 
   *  @return a new range with a different step 
   */  
  def by(step: Int): Range = copy(start, end, step)  
  
  def isInclusive = false  
  
  @inline final override def foreach[@specialized(Unit) U](f: Int => U) {  
    if (length > 0) {  
      val last = this.last  
      var i = start  
      while (i != last) {  
        f(i)  
        i += step  
      }  
      f(i)  
    }  
  }  

```

这里重写了foreach方法，其实就是遍历每个元素时给i+=step。
其实返回的是一个range对象


```
scala> List(1 to 100 by 2)  
res77: List[scala.collection.immutable.Range] = List(Range(1, 3, 5, 7, 9, 11, 13  
, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45, 47, 49, 51, 53  
, 55, 57, 59, 61, 63, 65, 67, 69, 71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93  
, 95, 97, 99))  
```

想要转换为int，则需要

```scala
scala> List(1 to 100 by 2:_*)  
res78: List[Int] = List(1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 3  
1, 33, 35, 37, 39, 41, 43, 45, 47, 49, 51, 53, 55, 57, 59, 61, 63, 65, 67, 69, 7  
1, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93, 95, 97, 99)  
```