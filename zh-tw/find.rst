**********
精通資料檢索
**********

第一章提供 ``find`` 指令的粗淺介紹，\
``find`` 除了選擇器（\ ``selectors``\ ）還有更多需要瞭解的地方。\
我們已經提過 ``find`` 返回的結果是一個指標（\ ``cursor``\ ），\
本章會做更多的介紹。

選取指定欄位
===========

在我們開始進入指標（\ ``cursors``\ ）之前，\
你必須先知道 ``find`` 具有第二個參數，\
這個參數是我們想要取得的欄位清單。\
舉例來說，我們如果只要取得獨角獸的名字，可以執行：

::

    db.unicorns.find(null, {name: 1});

預設的情況是，主鍵 ``_id`` 欄位不管是否在清單中，都會包含在查詢結果中。\
如果要指定不回傳主鍵，可以執行 ``{name: 1, _id: 0}`` 。

除了 ``_id`` 欄位之外，\
你無法混合且符合包含與排除的設定。\
關於這點只要多加思考一下，\
就會發現這很合理，\
你對要選擇或排除什麼欄位應該要有清楚的條件。

排序
====

我提到幾次 ``find`` 回傳一個指標（cursor），\
它使取得實際資料的執行延遲直到真正需要的時候。\
然而在使用 shell 時你會觀察到 ``find`` 會立即執行，\
這個行為只會發生在 shell。\
如果我們將其他的方法（methods）串連到 ``find`` 時，\
就可以觀察指標（cursors）真正的行為。\
首先我們看到的是 ``sort``\ ，\
它和上一節選取欄位很相似。\
我們可以指定用於排序的欄位，\
使用 1 代表升冪序，而 -1 則代表降冪序。\
例如：

::

    //最重的獨角獸顯示在最前面
    db.unicorns.find().sort({weight: -1})

    //依獨角獸名字及殺死的吸血鬼數量:
    db.unicorns.find().sort({name: 1, vampires: -1})

就像關聯式資料庫，MongoDB 可以將索引用於排序，\
我們之後會更詳細介紹索引，\
然而，你必須知道在沒有索引的情況下，MongoDB 會限制排序的大小。\
意思是，如果你試著對一個很龐大的查詢結果做排序，\
但是沒有使用索引，你會得到錯誤訊息。\
有些人將這看成一種限制性；\
但事實上，我希望更多資料庫都有這種防止執行未最佳化查詢的功能。\
（我並非將 MongoDB 的每個缺點都視為正面的，\
但是我實在看過很多資料庫存取都相當缺乏最佳化，我很希望有個較嚴格的限制。）

分頁
====

查詢結果的分頁可以透過指標的 ``limit`` 及 ``skip`` 方法來完成，\
例如要取得重量排行第二及第三的獨角獸，我們可以這樣做：

::

    db.unicorns.find().sort({weight: -1}).limit(2).skip(1)

結合 ``limit`` 與 ``sort`` 是一個好的方法，\
可以避免在非索引欄位排序時發生問題。

計算資料筆數
==========

在 shell 中可以直接對資料集合（collection）呼叫 ``count``\ ，\
像是：

::

    db.unicorns.count({vampires: {$gt: 50}})

事實上，\ ``count``\ 實際上是指標（\ ``cursor``\ ）提供的方法，\
而 shell 是提供簡化的語法。\
在開發時所使用的驅動程式，\
並不會提供這種簡化的語法，\
所以必須用以下的方式計算數量（當然在 shell 這也是行得通的）。

::

    db.unicorns.find({vampires: {$gt: 50}}).count()

重點回顧
=======

``find`` 及指標（\ ``cursors``\ ）的使用很簡單易懂。
雖然還有少數的指令會在後續的章節中提到，\
或是一些特例的情況；\
但你現在對於使用 mongo shell 應該會感到暢快，\
你已經瞭解 MongoDB 的基礎。
