****
基礎
****

現在就開始我們的旅程，先來認識 MongoDB 的基本功夫。\
這是瞭解 MongoDB 的核心，\
同時也可以幫助我們回答 MongoDB 適用與否的高階問題。

在開始之前，有六個簡單的概念我們需要瞭解：

1. MongoDB 和一般認知的「資料庫 ``database``\ 」其實是相同概念\
   （或者在 Oracle 被稱為「綱要 ``schema``\ 」），\
   在一個 MongoDB 的實體（instance）中，\
   你可以建立一或多個資料庫，
   每一個都可以扮演用於儲存任何物件的高階容器（containers）。

2. 一個資料庫可以包含零或多個「資料集合 ``collection``\ 」，\
   可以把資料集合想像成是傳統的「資料表 ``table``\ 」，\
   你可以先把它們當作相同東西思考。

3. 資料集合由零或多個「文件 ``document``\ 」組成，\
   同樣地，你也可以把文件想成「資料列 ``row``\ 」。

4. 文件則是由一或多個「欄位 ``field``\ 」，\
   和你猜想的一樣，它就像是「資料欄 ``column``\ 」。

5. 「索引 ``index``\ 」在 MongoDB 的作用則和 RDBMS 相同。

6. 「指標 ``cursor``\ 」則和其它五個概念不一樣，\
   它的重要程度不足以致於常被忽視。\
   但你必須瞭解指標的用處，\
   當你需要向 MongoDB 要求資料時，\
   它會回傳一個指標，\
   透過它就可以計算資料筆數或略過一些資料，\
   而不用真的傳遞資料。

概括來說，MongoDB 由包含資料集合（collections）的資料庫（databases）組成，\
而資料集合則是文件（documents）組成，\
每個文件則由欄位（fields）組成。\
資料集合可以被索引（indexed），\
可以使資料搜尋或排序的效率更好。\
最後，當我們向 MongoDB 要求資料時，\
會回傳一個指標（cursor），\
資料會延遲到真正需要時才傳遞。

你可能會想知道，\
為何使用新的術語（collection vs. table, document vs. row and field vs. column），\
這不是讓事情變得更複雜嗎？\
事實上這些術語雖然和關聯式資料庫的用法類似，\
但是並非全然相同。\
主要的差異是：實際上關聯式資料庫將 ``columns`` 定義在 ``table`` 層級，\
而文件導向資料庫則將 ``fields`` 定義在 ``document`` 層級。\
意思就是在 ``collection`` 包含的每個 ``document`` 都可以擁有自己獨特的 ``fields`` 定義。\ 
也就是說，\ ``collection`` 是比 ``table`` 是更簡化的容器，\
而 ``document`` 則比 ``row`` 包含更多資訊。

儘管瞭解這些概念很重要，但是如果目前仍有不清楚，先不必擔心，\
稍後的一些示範就可以看到這些概念真正的意義。\
重點是，資料集合對它要保存的東西並沒有嚴格定義（schema-less），\
在每個獨立的文件可以有各自不同的欄位記錄，\
這種設計的優缺點將在未來的章節中發現。

讓我們開始動手，如果你還沒執行程式，\
請回到前面啟動 ``mongod`` 伺服器及 ``mongo`` shell 指令的步驟。\
mongo shell 可以用來執行 JavaScript 程式碼。\
有一些全域指令可以執行，像是 ``help`` 或 ``exit`` 等，\
用來操作目前資料庫的指令是 ``db`` 物件，\
像是 ``db.help()`` 或 ``db.stats()`` 。\
如果你要操作特定的資料集合，\
則使用 ``db.COLLECTION_NAME`` 物件，\
像是 ``db.unicorns.help()`` 或者 ``db.unicorns.count()`` ，\
這是我們將會頻繁使用的指令。

輸入 ``db.help()`` 你可以取得一串指令說明，\
告訴你如何執行及操作 ``db`` 物件。

有個小地方需要注意，因為 shell 使用 JavaScript 語言，\
如果你執行一個方法（method）而沒有加上括號 ``()``\ ，\
螢幕只會將方法的內容印出來，\
而不是實際執行這個方法。\
這個提醒是希望當你看到 ``function (...){`` 這種回應訊息時，\
請不要感到驚訝。\
舉例來說，如果輸入 ``db.help``\ （沒有加上括號），\
你就會看到 ``help`` 這個方法的內部實作。

首先我們會用全域指令 ``use`` 這個方法來切換資料庫，\
例如輸入 ``use learn`` 時，\
即使這個資料庫並不存在，\
當我們在其中建立第一筆 collection 時，\
就會自動建立 ``learn`` 資料庫。\
此時，你已經在資料庫裡面，\
你可以開始使用資料庫指令，\
像是 ``db.getCollectionNames()`` ，\
在執行之後，會得到一個空白的陣列（\ ``[ ]``\ ）。\
因為 collection 的結構並不需要事先定義，\
所以我們也不需要明確定義 collection。\
我們可以很簡單地插入一筆新的 document 到一個新的 collection，\
方法是使用 ``insert`` 這個指令，\
只要將文件資料當作參數：

::

    db.unicorns.insert({name: 'Aurora', gender: 'f', weight: 450})

上面的程式是對 ``unicorns`` 執行 ``insert`` 指令，\
將一個單筆參數傳入，\
MongoDB 內部使用二進位序列化（binary seralized）的 JSON 格式，\
從外部來說，這意謂著我們將大量使用 JSON 當作我們的參數。\
如果我們現在執行 ``db.getCollectionNames()`` ，\
將會看到兩個 collection 包括 ``unicorns`` 及 ``system.indexes`` 。\
``system.indexes`` 在每個資料庫只會建立一次，\
用來保存資料庫索引的資訊。

你現在可以對 ``unicorns`` 使用 ``find`` 指令，\
取得 document 的列表。

::

    db.unicorns.find()

請注意，除了你定義的資料外，還會多一個 ``_id`` 的欄位，\
每個文件都會有一個獨一無二的 ``_id`` 欄位，\
你可以自行建立或者讓 MongoDB 幫你產生一個 ObjectId 物件，\
通常你會想要讓 MongoDB 幫你建立。\
預設的情況是，\ ``_id`` 欄位會被列入索引，\
這也是 ``system.indexes`` 資料集合會被自動建立的原因，\
你可以自己看一下 ``system.indexes`` 的內容：

::

    db.system.indexes.find()

你將會看到索引的名稱，以及資料庫、資料集合和被索引的欄位名稱。

現在，回到我們有關於 collection 不需要定義（schema-less）的討論，\
插入一筆完全不同的文件到目前的 ``unicorns`` 資料庫，像是：

::

    db.unicorns.insert({name: 'Leto', gender: 'm', home: 'Arrakeen', worm: false})

接著，再次使用 ``find`` 列出所有文件。\
現在我們已經多瞭解一點，\
未來我們會再討論 MongoDB 這種有趣的行為，\
希望你已經開始瞭解為什麼關聯式資料庫的傳統術語並不適用於此。

精通資料選擇器（Selectors）
==========================

除了前面已經講過的六個概念，\
在進入更進階的主題之前，\
你還需要對「查詢選擇器（query selectors）」有更多掌握。\
MongoDB 的查詢選擇器，就像是 SQL 語法中的 ``where`` ，\
透過它，你可以從資料集合（collection）中對文件（document）\
進行尋找（find）、計算數量（count）、修改（update）或刪除（remove），\
選擇器是使用 JSON 的物件，\
最簡單的情況就是 ``{}`` 用於找出全部文件（\ ``null`` 也有相同作用）。\
如果我們想要找出所有母獨角獸，\
我們可以使用 ``{gender: 'f'}``\ 。

在我們繼續深入探索選擇器之前，\
我們先來建立一些測試資料。\
首先我們使用 ``db.unicorns.remove()`` 將之前對 ``unicorns`` 插入的資料清除\
（因為在 remove 並未傳入任何選擇器當作參數，所以會清除所有資料）。\
現在，執行下列的程式碼讓我們插入一些測試資料（建議讀者用複製、貼上）：

.. literalinclude:: ../src/import1.js
   :language: javascript

現在我們已經有了資料，可以開始使用選擇器。\
``{field: value}`` 代表用於找出所有 ``field`` 的值等於 ``value`` 的 document。\
``{field1: value1, field2: value2}`` 則類似使用 SQL 的 ``and`` 語法，\
還有特殊的 ``$lt, $lte, $gt, $gte, $ne`` 運算子（operator）可以使用，\
分別代表小於、小於或等於、大於、大於或等於、不等於的操作，\
舉例來說，如果要取得所有公獨角獸、並且重量超過700磅，\
我們可以這麼做：

::

    db.unicorns.find({gender: 'm', weight: {$gt: 700}})
    //或者（以下用法雖然意義有些不同，但可以達到測試目的）
    db.unicorns.find({gender: {$ne: 'f'}, weight: {$gte: 701}})

運算子 ``$exists`` 用來找出某個欄位（field）存在或不存在的文件（document），例如：

::

    db.unicorns.find({vampires: {$exists: false}})

這個範例傳回一筆 document，如果我們想要使用 OR 而不是 AND 運算，\
可以使用 ``$or`` 運算子，並且指派一個陣列當作它的值：

::

    db.unicorns.find({gender: 'f', $or: [{loves: 'apple'}, {loves: 'orange'}, {weight: {$lt: 500}}]})

上面的例子回傳所有母獨角獸，\
每個都符合喜歡蘋果、喜歡橘子或重量小於500磅其中一項條件。

這個例子看起來已經相當不錯，\
也許你已經注意到：\ ``loves`` 欄位是一個陣列的資料型態。\
MongoDB 支援將陣列當作第一級物件（first class objects），
這是一種極為靈活的特性，\
在你試過之後就會發現自己無法回頭了。
用陣列的值進行簡單的資料篩選相當有趣，
例如 ``{loves: 'watermelon'}`` 將會傳回所有 ``loves`` 的值是 ``watermelon`` 的文件。

後續的章節我們會看到更多可用的運算子，\
其中最具有彈性的運算子是 ``$where`` ，\
它可以提供一段 JavaScript 並且在資料庫伺服器上面執行。\
這些都在 MongoDB 的\
`進階查詢 <http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries>`_\
文件中可以找到。\
我們到目前為止的討論都是讓你入門的基礎，\
在你實際開發時也會經常用到。

我們看到這些選擇器，\
如何搭配 ``find`` 指令使用，\
它們也可以和之前介紹過的 ``remove`` 指令一起搭配，\
或者是我們還沒看過的 ``count`` 搭配（你可以從名稱猜出這是用來計算資料筆數），\
還有我們之後會花更多時間介紹的 ``update`` 也能使用選擇器。

由 MongoDB 幫我們 ``_id`` 欄位產生的 ``ObjectId`` ，可以用以下的方式選取：

::

    db.unicorns.find({_id: ObjectId("TheObjectId")})

重點回顧
========

我們還沒看到 ``update`` 語法或其他更炫的 ``find`` 用法，\
然而，我們已經讓 MongoDB 啟動執行，\
也很快看過 ``insert`` 及 ``remove`` 指令（它能做的也只有這麼多了），\
我們也介紹 ``find`` 及搭配 MongoDB 的 ``selectors`` 一起使用，\
我們已經有了好的開始，為接下來的學習打好穩固的基礎。\
不管你相信或不信，你確實已經知道 MongoDB 有哪些東西需要瞭解，\
它就是如此迅速學習、容易使用。\
我強烈建議你在繼續閱讀之前，\
多玩一下你的 MongoDB，\
試著加入不同的文件，\
可以建立新的資料集合，\
或是熟悉其它不同的選擇器用法。\
使用 ``find``\ 、\ ``count``\ 及\ ``remove``\ 等方法。\
當你自己試過幾次之後，\
就不會像剛開始那樣不熟練。

