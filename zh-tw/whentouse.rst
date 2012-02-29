******************
使用 MongoDB 的時機
******************

現在你對 MongoDB 應該有足夠的瞭解，\
你可以知道 MongoDB 該用在你系統的什麼地方，以及要如何使用它。\
但是有太多新的資料儲存技術，\
使得從中作選擇是一項重擔。

對我來說，最重要的課題是，使用 MongoDB 可以使我們不必再依賴單一資料庫解決方案。\
毫無疑問的，採用單一的資料庫解決方案，對許多專案而言具有明顯的優勢，\
幾乎可說是最明智的選擇。\
但我的想法並非你一定要同時用不同的技術，\
而是你可以選擇要或不要。\
只有你自己最清楚導入新技術的利益是否會得不償失。

也就是說，我希望你可以看得更遠，將 MongoDB 當做一個通用的解決方案。\
前面提過好幾次，文件導向資料庫和關聯式資料庫有諸多共通之處。\
因此，許多資訊讓我們誤認為 MongoDB 是用來直接取代關聯式資料庫。\
有人可能會將 Lucene 視為關聯式資料庫全文檢索功能的加強版，\
或是將 Redis 當做持久化 key-value 儲存體，\
而將 MongoDB 認定 是你的資料儲存中心。

請注意我並沒有將 MongoDB 稱為關聯式資料庫的\ *取代*\ 方案，\
而是\ *替代*\ 方案。\
它的功能有許多其他工具也能辦到，\
有些 MongoDB 的功能很棒，\
但也有些很糟糕。\
這一章就讓我們來作稍微多一點的剖析。

Schema-less
===========

文件導向資料庫常被宣揚的好處是 schema-less，\
比起傳統資料庫的資料表，這是一種更具彈性的作法。\
我同意 schema-less 是很棒的特色，\
但不是
An oft-touted benefit of document-oriented database is that they are
schema-less. This makes them much more flexible than traditional
database tables. I agree that schema-less is a nice feature, but not for
the main reason most people mention.

People talk about schema-less as though you'll suddenly start storing a
crazy mismatch of data. There are domains and data sets which can really
be a pain to model using relational databases, but I see those as edge
cases. Schema-less is cool, but most of your data is going to be highly
structured. It's true that having an occasional mismatch can be handy,
especially when you introduce new features, but in reality it's nothing
a nullable column probably wouldn't solve just as well.

For me, the real benefit of schema-less design is the lack of setup and
the reduced friction with OOP. This is particularly true when you're
working with a static language. I've worked with MongoDB in both C# and
Ruby, and the difference is striking. Ruby's dynamism and its popular
ActiveRecord implementations already reduce much of the
object-relational impedance mismatch. That isn't to say MongoDB isn't a
good match for Ruby, it really is. Rather, I think most Ruby developers
would see MongoDB as an incremental improvement, whereas C# or Java
developers would see a fundamental shift in how they interact with their
data.

Think about it from the perspective of a driver developer. You want to
save an object? Serialize it to JSON (technically BSON, but close
enough) and send it to MongoDB. There is no property mapping or type
mapping. This straightforwardness definitely flows to you, the end
developer.

資料寫入（Writes）
===============

MongoDB 很適合用於記錄（logging），\
有兩項因素使 MongoDB 可以用十分快的速度寫入資料，\
首先，你可以送出一個寫入指令，並立即得到回傳，而不必等候資料真正被寫入。\
第二點，在 1.8 加入並在 2.0 加強的日誌（journaling）功能，\
你可以依照資料可靠度來控制寫入行為，\
這些設定包括有多少資料庫伺服器取得你的資料才被視為完成，\
可以對個別的寫入調整設定，\
讓你在寫入效能及資料可靠度之間有很好的控制權。

除了這些效能因素，記錄資料也可以藉由資料集合的 schema-less 特性得到好處，\
最後，MongoDB 還有一種稱為
`capped collection <http://www.mongodb.org/display/DOCS/Capped+Collections>`_
的東西，我們之前所建立過的資料集合只是一般預設，\
我們可以使用 ``db.createCollection`` 指令建立資料集合，並標示它為受限（capped）：

::

    //限制資料集合最多只能有 1MB 容量
    db.createCollection('logs', {capped: true, size: 1048576})

當受限的資料集合達到 1MB 容量限制，\
舊的文件會被自動移除，\
如果要改以文件數量、而非容量，\
可以使用 ``max`` 設定。\
受限的資料集合有一些有趣的屬性，\
舉例來說，你可以更新一筆文件，但它不會增加容量，\
同時，插入的順序也已經預留，\
所以你不需要增加一個額外的索引用於時間為基礎的排序。

這裡很適合說明，如果你想知道寫入資料時是否發生錯誤，\
你可以簡單地執行這段指令 ``db.getLastError()``\ ，\
多數的驅動程式將這個檢查封裝成\ *安全寫入*\ ，\
通常只要在 ``insert`` 的第二個參數指定 ``{:safe => true}``\ 。

Durability
~~~~~~~~~~

在 1.8 版以前，MongoDB 並沒有單一伺服器的可靠度功能，\
意思就是，當伺服器故障可能造成資料遺失，\
而解決方法是採用多伺服器設定來執行 MongoDB（支援 replication 複寫模式）。\
在 1.8 版增加的主要功能就是日誌（journaling）， \
要開啟這項功能只要在 ``mongodb.config`` 設定檔加入一行 ``journal=true``\ ，\
這是我們一開始在安裝 MongoDB 時建立的設定檔，\
修改設定後重新啟動 MongoDB 伺服器即可發揮作用。\
你可能會想要使用日誌（未來版本會成為預設選項），\
儘管，有些情況將日誌關閉可以增加一些產出（throughput），
不過這也會帶來風險。\
（這裡必須說明的是，有些應用程式即使遺失資料也不會有什麼影響。）

我們只在這裡談論資料可靠度，\
因為有不少資料談論 MongoDB 缺少單一伺服器資料可靠度的問題，\
在 Google 搜尋中就可以發現不少，\
但你找到的這些資訊可能已經過時。

全文搜尋（Full Text Search）
=========================

希望在 MongoDB 未來的版本可以提供真正全文搜尋的功能；\
有了它對陣列的支援，要實作基本的全文搜尋很容易。\
如果需要更強大的全文檢索，可能就要搭配 Lucene/Solr 解決方案，\
就像許多關聯式資料庫一樣。

資料交易（Transactions）
======================

MongoDB 並沒有交易功能，它有兩種替代方案，一種很棒但用起來有限制，另一種很累贅但卻有彈性。

第一種是 MongoDB 的諸多基本運算，它們很棒，\
確實可以解決你的問題，\
我們已經看過一些較簡單的，如 ``$inc`` 及 ``$set``\ ，\
也有其他指令像 ``findAndModify`` 可以一次完成更新或刪除文件的動作。

第二種，當基本運算不夠用，就必須回到兩階段 commit，\
The second, when atomic operations aren't enough, is to fall back to a
two-phase commit. A two-phase commit is to transactions what manual
dereferencing is to joins. It's a storage-agnostic solution that you do
in code. Two-phase commits are actually quite popular in the relational
world as a way to implement transactions across multiple databases. The
MongoDB website `has an
example <http://www.mongodb.org/display/DOCS/two-phase+commit>`_
illustrating the most common scenario (a transfer of funds). The general
idea is that you store the state of the transaction within the actual
document being updated and go through the init-pending-commit/rollback
steps manually.

MongoDB's support for nested documents and schema-less design makes
two-phase commits slightly less painful, but it still isn't a great
process, especially when you are just getting started with it.

資料處理
=======

MongoDB 採用 MapReduce 負責大部分的資料處理工作，\
在
`basic aggregation <http://www.mongodb.org/display/DOCS/Aggregation>`_
有一些基本運算功能，\
但你可能會想用 MapReduce。\
在下一章我們會仔細看 MapReduce，\
現在，你只需要將它想成非常強大而且不同以往的 ``group by``\ （實際上並無此語法），\
MapReduce 的長處之一，是它可以對大型資料集進行平行運算處理，\
然而，MongoDB 的實作是採用 JavaScript，\
而且是單一執行緒，\
關於這一點，你可能想用其他方式如 Hadoop。\
真是感謝，如果真的要讓這兩種系統互補有無，\
可以透過
`MongoDB adapter for Hadoop <https://github.com/mongodb/mongo-hadoop>`_\ 。

當然，平行資料處理並非用關聯式資料庫就能做得更好，\
在 MongoDB 未來的版本，將會有計畫地將超大型資料集的處理做得更好。

地理空間資料（Geospatial）
=======================

MongoDB 有個特別強大的功能，就是它支援地理資料索引，\
因此你可以在文件中儲存 x 及 y 座標，\
並使用 ``$near`` 以一組座標來找出一筆座標鄰近的文件，\
或者使用 ``$within`` 找到在一個方形或圓形範圍內的文件。\
用視覺化比較容易解釋這項功能，如果你想知道更多，建議你可以參考
`5 minute geospatial interactive tutorial <http://mongly.com/geo/index>`_\ 。

工具與發展
=========

你或許已經知道，\
MongoDB 比起大多關聯式資料庫系統要年輕許多，\
這絕對是你需要考慮的事情，\
How much a factor it plays depends on what you are doing and how you are doing it.
Nevertheless, an honest assessment simply can't ignore the fact that MongoDB is younger and the available tooling around isn't great (although the tooling around a lot of very mature relational databases is pretty horrible too!). 
As an example, the lack of support for base-10 floating point numbers will obviously be a concern (though not necessarily a show-stopper) for systems dealing with money.

站在正面的一方，它已經有相當多程式語言的驅動函式庫，\
協定很現代化及簡單，\
而且正以看不見得速度發展，\
有夠多的公司將 MongoDB 用於實際產品或服務，\
讓它的未來發展。
MongoDB is in production at enough companies that concerns about
maturity, while valid, are quickly becoming a thing of the past.

重點回顧
=======

本章要揭露的訊息，就是 MongoDB 在大部分情況中，可以取代傳統資料庫。\
它更簡單直接，速度更快，通常可以讓應用程式開發者受到較少的限制；\
但是缺少交易機制的問題則需要合理、認真考慮。\
無論如何，當人們問：「在新的資料儲存領域中，MongoDB 有何處可以立足？」\
答案很簡單：「就在中間。」
