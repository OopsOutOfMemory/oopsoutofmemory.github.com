---
layout: post
title: 推荐算法总结Recommendation
category: Machine Learning
date: 2014-11-15
---

目前为止，我们常推荐算法有好多种，比较常见的有协同过滤（Collaborative Filtering Recommendations）这个在Mahout里的ItemCF和UserCF比较常用，还有一种比较新的运行在Spark上的交替性最小二乘ALS也是一种协同过滤的算法，但是其它的推荐算法也有很多，在日常中也用的比较多，就做个总结吧。

## 1、基于内容的推荐算法(Content Based Recommendation 简称CB)
这种推荐是从信息检索，和文本检索里来的，个人理解为是搜索引擎里的搜索排行。``TD-IDF``计算文章的词频和反文档频率计算出关键词在文档中的权值，最后构成某篇文章的特征向量。基于该文章的特征向量和其它文章的特征向量进行余弦相似度计算，从而返回最匹配相似的文章来给予推荐。

可以简单概括为: ``抽取item的特征向量`` -> ``计算余弦相似度`` -> ``推荐``

``item``可以是用户过去喜欢的电影，商品，问题等等。
基于内容的过滤创建了每个商品、用户的属性（或是组合）用来描述其本质。比如对于电影来说，可能包括演员、票房程度等。 

``用户属性信息``可能包含地理信息、问卷调查的回答等。这些属性信息关联用户用户后即可达到匹配商品的目的。 当然基于内容的策略极有可能因为信息收集的不便而导致无法实施。
CB的优点：

1. 用户之间的独立性（User Independence）：既然每个用户的profile都是依据他本身对item的喜好获得的，自然就与他人的行为无关。而CF刚好相反，CF需要利用很多其他人的数据。CB的这种用户独立性带来的一个显著好处是别人不管对item如何作弊（比如利用多个账号把某个产品的排名刷上去）都不会影响到自己。

2. 好的可解释性（Transparency）：如果需要向用户解释为什么推荐了这些产品给他，你只要告诉他这些产品有某某属性，这些属性跟你的品味很匹配等等。

3. 新的item可以立刻得到推荐（New Item Problem）：只要一个新item加进item库，它就马上可以被推荐，被推荐的机会和老的item是一致的。而CF对于新item就很无奈，只有当此新item被某些用户喜欢过（或打过分），它才可能被推荐给其他用户。所以，如果一个纯CF的推荐系统，新加进来的item就永远不会被推荐:( 。

``CB的缺点``：

1. item的特征抽取一般很难（Limited Content Analysis）：如果系统中的item是文档（如个性化阅读中），那么我们现在可以比较容易地使用信息检索里的方法来“比较精确地”抽取出item的特征。但很多情况下我们很难从item中抽取出准确刻画item的特征，比如电影推荐中item是电影，社会化网络推荐中item是人，这些item属性都不好抽。其实，几乎在所有实际情况中我们抽取的item特征都仅能代表item的一些方面，不可能代表item的所有方面。这样带来的一个问题就是可能从两个item抽取出来的特征完全相同，这种情况下CB就完全无法区分这两个item了。比如如果只能从电影里抽取出演员、导演，那么两部有相同演员和导演的电影对于CB来说就完全不可区分了。

2. 无法挖掘出用户的潜在兴趣（Over-specialization）：既然CB的推荐只依赖于用户过去对某些item的喜好，它产生的推荐也都会和用户过去喜欢的item相似。如果一个人以前只看与推荐有关的文章，那CB只会给他推荐更多与推荐相关的文章，它不会知道用户可能还喜欢数码。

3. 无法为新用户产生推荐（New User Problem）：新用户没有喜好历史，自然无法获得他的profile，所以也就无法为他产生推荐了。当然，这个问题CF也有。



## 2、基于协同过滤的推荐算法（Collaborative Filtering Recommendations）
基于协同过滤的推荐，可以理解为基于用户行为的推荐。依赖于用户过去的行为的协同过滤，行为可以是过往的交易行为和商品评分，这种方式不需要显性的属性信息。协同过滤通过分析用户和商品的内在关系来识别新的 user-item 关系。

协同过滤领域主要的两种方式是最近邻（neighborhood）方法和潜在因子（latent factor）模型。最近邻方法主要集中在 item 的关系或者是 user 的关系，是比较基础的过滤引擎。而潜在因子模型并不是选取所有的关系，而是通过矩阵分解的技术将共现矩阵的分解，比如提取20-100个因子，来表示原始矩阵信息（可以对比上面提到的音乐基因，只不过潜在因子模型是通过计算机化的实现）。

``最邻近：``

基于用户的协同过滤算法: 基于一个这样的假设“跟你喜好相似的人喜欢的东西你也很有可能喜欢。”所以基于用户的协同过滤主要的任务就是找出用户的最近邻居，从而根据最近邻 居的喜好做出未知项的评分预测。

``item based CF 基于物品相似的协同过滤。``

``user based CF 基于用户相似的协同过滤。``

潜在引子模型：

``SVD奇异值分解矩阵``

``ALS交替最小二乘``

总结为： ``用户评分`` -> ``计算最邻近``  -> ``推荐``

## 3、算法对比

<table class="table-view log-set-param  " style="border-collapse:collapse; border-spacing:0px; margin:5px 0px; word-wrap:break-word; word-break:break-all; font-size:12px; line-height:22px; color:rgb(0,0,0); font-family:arial,宋体,sans-serif">
<tbody>
<tr>
<td width="0" height="0" align="left" valign="middle" colspan="3" rowspan="0" style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">表1 主要推荐方法对比</div>
</td>
</tr>
<tr>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
推荐方法</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
优点</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
缺点</td>
</tr>
<tr>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
基于内容推荐</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
推荐结果直观，容易解释；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">不需要领域知识</div>
</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
新用户问题；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">复杂属性不好处理；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">要有足够数据构造分类器</div>
</td>
</tr>
<tr>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
协同过滤推荐</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
新异兴趣发现、不需要领域知识；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">随着时间推移性能提高；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">推荐个性化、自动化程度高；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">能处理复杂的非结构化对象</div>
</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
稀疏问题；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">可扩展性问题；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">新用户问题；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">质量取决于历史数据集；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">系统开始时推荐质量差；</div>
</td>
</tr>
<tr>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
基于规则推荐</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
能发现新兴趣点；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">不要领域知识</div>
</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
规则抽取难、耗时；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">产品名同义性问题；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">个性化程度低；</div>
</td>
</tr>
<tr>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
基于效用推荐</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
无冷开始和稀疏问题；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">对用户偏好变化敏感；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">能考虑非产品特性</div>
</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
用户必须输入效用函数；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">推荐是静态的，灵活性差；</div>
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">属性重叠问题；</div>
</td>
</tr>
<tr>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
基于知识推荐</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
能把用户需求映射到产品上；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">能考虑非产品属性</div>
</td>
<td style="margin:0px; padding:2px 10px; height:22px; border:1px solid rgb(230,230,230)">
知识难获得；
<div class="para" style="color:rgb(51,51,51); margin:0px; line-height:24px">推荐是静态的</div>
</td>
</tr>
</tbody>
</table>

## 四、 Mahout里的推荐算法


## 五、总结

没有最那一种算法能解决所有问题，混合算法有效结合每个算法的利弊才能达到最好的效果。

一个比较成功的内容过滤是 pandora.com 的音乐基因项目，一个训练有素的音乐分析师会对每首歌里几百个独立的特征进行打分。这些得分帮助pandora推荐歌曲。还有一种基于内容的过滤是基于用户人口统计特征的推荐，先根据人口统计学特征将用户分成若干个先验的类。对后来的任意一个用户，首先找到他的聚类，然后给他推荐这个聚类里的其他用户喜欢的物品。这种方法的虽然推荐的粒度太粗，但可以有效解决注册用户的冷启动(Cold Start)的问题。

---

参考文献：

<http://baike.baidu.com/link?url=En0sSiwP9wghUjBkT6BxvVODH1YbwhGqQ7ECEuesuARi_Hcz1G25WMlm3Q0actt6LRyNd00TmY5MBH3u76hQM_>
<http://www.cnblogs.com/breezedeus/archive/2012/04/10/2440488.html>
<http://www.bjt.name/2013/06/recommendation-system/>
<http://hnote.org/big-data/mahout/mahout-movielens-example-matrix-factorization>
<http://blog.fens.me/mahout-recommendation-api/>