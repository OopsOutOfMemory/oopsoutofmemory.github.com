---
layout: post
title: Scala协变逆变上界下界---理解篇
category: 
- scala
tags: [scala]
date: 2014-11-19
---

Scala的协变和逆变上界与下界

## 1. 引子：

为了弄懂scala中协变和逆变这两个概念，查阅了不少资料，但是还是要自己总结一下，会记得比较深刻。
那就从java和scala的对比说起吧。

java中：
如果你很理解java的泛型，就会知道：比如给定一个类B，和他的父类A。
那么用多态， A a = new B 编译器是允许的。
但是如果泛型B的集合直接赋给父类A的集合。

```List<A> aList = new ArrayList<B>(); ```


举个简单的例子：

```java
Object s = "abc";  
List<Object> objects = new ArrayList<String>();  
```

编译不通过，编译器提示：

```java
Type mismatch: cannot convert from ArrayList<String> to List<Object>  
```

scala中:
我们知道sting是AnyRef的子类。直接赋值是可以的。
如果是将string的集合赋值给AnyRef的集合，在scala中也是可以的。


```scala
scala> val s:AnyRef = "abc"  
s: AnyRef = abc  
  
scala> var objects : List[AnyRef] = List[String]("abc","123")  
objects: List[AnyRef] = List(abc, 123)  
```

原因就在于List其实是支持协变的。

## 2. 协变

``[+T], covariant (or “flexible”) in its type parameter T，类似Java中的(? extends T), 即可以用T和T的子类来替换T，里氏替换原则。``

可以看到List的定义：

```scala
type List[+A] = scala.collection.immutable.List[A]  
```

协变的符号是``[+A]``，意味着支持泛型A的子类集合向A进行赋值。
在这个例子里是List的是支持协变的。


## 3.不变

``[T], invariant  in its type parameter T``

在scala可变集合中，MutableList是一个不变的类型。

定义：

```scala
class MutableList[A]  
extends AbstractSeq[A]  
......  
```

我们还用相似的场景，将一个MutableList的string类型付给MutableList的AnyRef类型，这样的赋值是不允许的。
编译器会提示class MutableList is invariant in type A. 即在类型A中MutableList是不支持协变和逆变的。

```scala
scala> import scala.collection.mutable._  
import scala.collection.mutable._  
  
scala> val a : MutableList[AnyRef] = MutableList[String]("abc")  
<console>:10: error: type mismatch;  
 found   : scala.collection.mutable.MutableList[String]  
 required: scala.collection.mutable.MutableList[AnyRef]  
Note: String <: AnyRef, but class MutableList is invariant in type A.  
You may wish to investigate a wildcard type such as `_ <: AnyRef`. (SLS 3.2.10)  
       val a : MutableList[AnyRef] = MutableList[String]("abc")  
                                                        ^  
```

## 4. 逆变

``[-T], contravariant, 类似(? supers T) ``

> if T is a subtype of type S, this would imply that Queue[S] is a subtype of Queue[T]

只能用T的父类来替换T。是逆里氏替换原则。
在  scala.actors.OutputChannel 这个trait是一个逆变的类型。


```scala
trait OutputChannel[-Msg] {  
......  
```

对于OutputChannel[String], 支持的操作就是输出一个string, 同样OutputChannel[AnyRef]也一定可以支持输出一个string, 因为它支持输出任意一个AnyRef(它要求的比OutputChannel[String]少) 。
但反过来就不行, OutputChannel[String]只能输出String, 显然不能替换OutputChannel[AnyRef]

## 5.上界与下界

__Scala的上界和下界比较难理解, 因为和Java里面的界不是一个意思...__

__Java中, (? extends T), T称为上界, 比较容易理解, 代表T和T的子类, (? supers T), T称为下界__


Scala中, 界却用于泛型类中的方法的参数类型上, 如下面的例子, 
对于Queue中的append的类型参数直接写T, 会报错 (error: covariant type T occurs in contravariant position in type T of value x) 

这个地方比较复杂, 简单的说就是Scala内部实现是, 把类中的每个可以放类型的地方都做了分类(+, –, 中立), 具体分类规则不说了 
对于这里最外层类[+T]是协变, 但是到了方法的类型参数时, 该位置发生了翻转, 成为-逆变的位置, 所以你把T给他, 就会报错说你把一个协变类型放到了一个逆变的位置上

所以这里的处理的方法就是, 他要逆变, 就给他个逆变, 使用[U >: T], 其中T为下界, 表示T或T的超类, 这样Scala编译器就不报错了

```scala
class Queue[+T] (private val leading: List[T],
                 private val trailing: List[T] ) {
  def append[U >: T](x: U) = new Queue[U](leading, x :: trailing) //使用T的超类U来替换T
}
```

同样对于上界也是,

```scala
trait OutputChannel[-T]
{
    def write [U<:T] (x: U) //使用T的子类U来替换T
}
```

可以参考：<http://www.cnblogs.com/fxjwind/p/3480462.html>

## 总结：

1. 协变
[+T], covariant (or “flexible”) in its type parameter T，类似Java中的(? extends T), 即可以用T和T的子类来替换T，里氏替换原则。

2. 不变
不支持T的子类或者父类，只知支持T本身。

3.逆变
[-T], contravariant, 类似(? supers T) 只能用T的父类来替换T。是逆里氏替换原则。

4. 上界：
只允许T的超类U来替换T。 [U >: T]

5. 下界：
只允许T的子类U来替代T。 [U <: T]

理解概念后，以后读源码的时候才不会不知云。