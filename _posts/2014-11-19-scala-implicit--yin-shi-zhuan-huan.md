---
layout: post
title:  Scala implicit 隐式转换
category: 
- scala
tags: [scala]
date: 2014-11-19
---

我们经常在scala 源码里上看到类似implicit这个关键字。
一开始不太理解，后来看了看，发现implicit这个隐式转换是支撑scala的易用、容错以及灵活语法的基础。
我们经常使用的一些集合方法里面就用到了implicit，比如：

```scala
def flatMap[B, That](f: A => GenTraversableOnce[B])(implicit bf: CanBuildFrom[Repr, B, That]): That = {  
```

### 1. 隐式转换函数的定义：
我们在scala repl里定义一个方法foo，接受一个string的参数，打印出message
 当我们传入字符串参数"2"的时候，输出2
 但是当传入的类型是int而不是string的时候，出现类型不匹配异常。
 如果我们想支持隐式转换，将int转化为string，可以定义一个隐式函数，def implicit intToString( i : Int) = i.toString
 这里注意一下这个隐式函数的输入参数和返回值。
 输入参数：接受隐式转换入参为int类型
 返回值： 返回结果是string.

```scala
scala> def foo(msg : String) = println(msg)  
foo: (msg: String)Unit  
  
scala> foo("2")  
2  
  
scala> foo(3)  
<console>:9: error: type mismatch;  
 found   : Int(3)  
 required: String  
              foo(3)  
                  ^  
  
scala> implicit def intToString(i:Int) = i.toString  
warning: there were 1 feature warning(s); re-run with -feature for details  
intToString: (i: Int)String  
  
scala> foo(3)  
3  

```

```scala
scala> def bar(msg : String) = println("aslo can use implicit function intToString...result is "+msg)  
bar: (msg: String)Unit  
```
```scala
scala> bar(33)  
```

aslo can use implicit function intToString...result is 33  
总结一下，我的理解是：隐式函数是在一个scop下面，给定一种输入参数类型，自动转换为返回值类型的函数，和函数名，参数名无关。
这里intToString隐式函数是作用于一个scop的，这个scop在当前是一个scala repl，超出这个作用域，将不会起到隐式转换的效果。

为什么我会这么定义隐式函数，下面我再定义一个相同的输入类型为int，和返回值类型为string的隐式函数名为int2str：

```scala
scala> implicit def int2str(o :Int) = o.toString  
warning: there were 1 feature warning(s); re-run with -feature for details  
int2str: (o: Int)String  
  
scala> bar(33)  
<console>:13: error: type mismatch;  
 found   : Int(33)  
 required: String  
Note that implicit conversions are not applicable because they are ambiguous:  
 both method intToString of type (i: Int)String  
 and method int2str of type (o: Int)String  
 are possible conversion functions from Int(33) to String  
              bar(33)  
                  ^  
```

跑出了二义性的异常，说的是intToString和int2str这2个隐式函数都是可以处理bar(33)的，编译器不知道选择哪个了，呵呵。。
证明了隐式函数和函数名，参数名无关，只和输入参数与返回值有关。

### 2. 隐式函数的应用

我们可以随便的打开scala函数的一些内置定义，比如我们最常用的map函数中->符号，看起来很像php等语言。
但实际上->确实是一个ArrowAssoc类的方法，它位于scala源码中的Predef.scala中。下面是这个类的定义：

```scala
final class ArrowAssoc[A](val __leftOfArrow: A) extends AnyVal {  
  // `__leftOfArrow` must be a public val to allow inlining. The val  
  // used to be called `x`, but now goes by `__leftOfArrow`, as that  
  // reduces the chances of a user's writing `foo.__leftOfArrow` and  
  // being confused why they get an ambiguous implicit conversion  
  // error. (`foo.x` used to produce this error since both  
  // any2Ensuring and any2ArrowAssoc pimped an `x` onto everything)  
  @deprecated("Use `__leftOfArrow` instead", "2.10.0")  
  def x = __leftOfArrow  
  
  @inline def -> [B](y: B): Tuple2[A, B] = Tuple2(__leftOfArrow, y)  
  def →[B](y: B): Tuple2[A, B] = ->(y)  
}  
@inline implicit def any2ArrowAssoc[A](x: A): ArrowAssoc[A] = new ArrowAssoc(x)  
```

我们看到def ->[B] (y :B)返回的其实是一个Tuple2[A,B]类型。
我们定义一个Map:

```scala
scala> val mp = Map(1->"game1",2->"game_2")  
mp: scala.collection.immutable.Map[Int,String] = Map(1 -> game1, 2 -> game_2)  
```

这里 1->"game1"其实是1.->("game_1")的简写。
这里怎么能让整数类型1能有->方法呢。
这里其实any2ArrowAssoc隐式函数起作用了，这里接受的参数[A]是泛型的，所以int也不例外。
调用的是：将整型的1 implicit转换为 ArrowAssoc(1)
看下构造方法，将1当作__leftOfArrow传入。
->方法的真正实现是生产一个Tuple2类型的对象(__leftOfArrow,y ) 等价于(1, "game_id")
这就是一个典型的隐式转换应用。

其它还有很多类似的隐式转换，都在Predef.scala中：
例如：Int，Long，Double都是AnyVal的子类，这三个类型之间没有继承的关系，不能直接相互转换。
在Java里，我们声明Long的时候要在末尾加上一个L，来声明它是long。
但在scala里，我们不需要考虑那么多，只需要：

```scala
scala> val l:Long = 10  
l: Long = 10  
```

这就是implicit函数做到的，这也是scala类型推断的一部分，灵活，简洁。
其实这里调用是：
```scala
val l : Long = int2long(10)
```

最后的总结：
1. 记住隐式转换函数的同一个scop中不能存在参数和返回值完全相同的2个implicit函数。
2. 隐式转换函数只在意 输入类型，返回类型。
3. 隐式转换是scala的语法灵活和简洁的重要组成部分。