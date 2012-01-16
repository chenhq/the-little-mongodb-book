**********
效能與工具
**********

最後一章，我們來看看幾個效能的主題，\
以及 MongoDB 開發者可用的工具。\
我們不會涉入太深，\
但是會兼顧各個重要的面向。

索引（Indexes）
==============

這本書一開始我們就看到特殊的 ``system.indexes`` 資料集合，\
它包含資料庫中所有索引的資訊。\
MongoDB 和關聯式資料庫的索引用途並沒有差異：\
它們都是用來改善查詢和排序的效能。\
索引的建立可以透過 ``ensureIndex`` 指令：

::

    db.unicorns.ensureIndex({name: 1});

移除索引可以用 ``dropIndex``\ ：

::

    db.unicorns.dropIndex({name: 1});

建立唯一索引（unique index）只需要將第二個參數中，將 ``unique`` 設定為 ``true`` 。

::

    db.unicorns.ensureIndex({name: 1}, {unique: true});

索引可以建立在內嵌欄位（使用 ``.`` 符號）與陣列欄位，\
我們也可以建立複合索引（compound indexes）：

::

    db.unicorns.ensureIndex({name: 1, vampires: -1});

你為索引設定的排序方式（1代表升冪、-1代表降冪），\
對單一鍵值的索引來說並沒有差異，\
但是在進行排序或使用一個範圍當查詢條件時，\
複合鍵索引的排序方式就會產生影響。

請參考\ `索引 <http://www.mongodb.org/display/DOCS/Indexes>`_\ 文件取得更多說明。

最佳化分析（Explain）
====================

要檢查索引是否對某個查詢起作用，\
可以使用指標（cursor）提供的 ``explain`` 方法。

::

    db.unicorns.find().explain()

執行這段程式的輸出告訴我們：\
``BasicCursor`` 指標被使用（意思就是沒有索引）、\
查詢過程掃描了12個物件、\
查詢花費的時間、\
使用什麼索引（如果有的話）\
以及其它少數有用的資訊。

如果我們修改這查詢，讓索引發生作用，\
我們將會看到指標類型使用 ``BtreeCursor``\ ，\
以及滿足這項查詢要求所用到的索引：

::

    db.unicorns.find({name: 'Pilot'}).explain()


寫入資料是否成功
================

我們在之前曾經提到，\
MongoDB 預設的資料寫入動作，\
並不包含最後是否完成的確認。\
雖然這樣做的結果可以有不錯的效能，\
但也可能導致資料遺失的風險。\
這種寫入方式帶來一個副作用，\
當新增或修改的資料違反唯一鍵的約束條件時，\
並不會回報錯誤。\
如果要知道寫入是否失敗，\
就必須在新增動作之後呼叫 ``db.getLastError()`` 。\
有些驅動程式可以透過額外的參數設定，\
提供\ **安全**\ 寫入的方法。

很不幸地，shell 功能並不會自動幫你做安全的資料新增，\
所以我們無法看到這個行為怎麼運作。

分割資料（Sharding）
===================

MongoDB 支援資料自動分割（auto-sharding），\
分割是一種擴展資料庫規模的方法，\
你可以讓資料分佈在多部伺服器。\
一種天真的想法是讓某個命名的全部資料都放在第一部伺服器，\
其他放在第二部伺服器。\
該高興的是，MongoDB 的資料分割能力遠超過這種簡單的邏輯。\
資料分割的主題已經遠超過這本書談論的範圍，\
但你仍必須先知道它的存在，\
當你需要利用超過一台以上的伺服器保存資料，\
就會需要用到它。

延伸閱讀：

* Sharding http://www.mongodb.org/display/DOCS/Sharding
* Scaling MongoDB http://shop.oreilly.com/product/0636920018308.do

複寫（Replication）
==================

MongoDB 也提供類似關聯式資料庫的複寫功能，\
寫入是由其中一台主伺服器（master）負責，\
主伺服器會將它的資料同步到其他副伺服器（slaves）。\
你的程式可以決定是否要從副伺服器讀取資料，\
這麼做的風險是程式可能讀取到過時的舊資料，\
但是可以將資料庫的負載分散到各伺服器。\
如果主伺服器毀損，\
可以改由其它伺服器擔任主伺服器。\
當然，複寫也不是本書談論的範圍。

雖然複寫可以改善效能（分散讀取的負載），\
但它主要目的應該是增加可靠度。\
常見的作法是將資料分割與複寫合併使用，\
例如每個負責分割資料的資料庫伺服器，\
都分成 master/slave 的角色。\
（就技術上來說，你會需要一個仲裁節點（arbiter），\
協助解決兩個 slave 都試著變成 master 的情況，\
仲裁節點需要的資源很少，可以用於多重資料分割。）

狀態查詢
========

你可以使用 ``db.stats()`` 取得資料庫的狀態數據，\
主要資訊是資料庫的資料量大小。\
你也可以執行 ``db.unicorns.stats()``
對資料集合（例如 ``unicorns``\ ）取得狀態，\
當然，最主要的資訊也是集合的資料量大小。

網頁管理介面（Web Interface）
============================

包含啟動 MongoDB 過程所顯示的資訊，\
都會顯示在內建的管理工具網頁\
（當然你也可以在 ``mongod`` 執行後將終端機畫面捲軸往上拉），\
你只需要用瀏覽器開啟 http://localhost:28017/ 網址，\
即可查詢這些訊息。\
除此之外，如果你在設定中加入 ``rest=true`` 並重新啟動 ``mongod`` 程序，\
可以獲得更多功能，例如：

利用 RESTful Web Services 取得 ``unicorns`` 的資料（查詢結果會以 JSON 格式顯示）：

http://localhost:28017/test/unicorns

記錄檢視器（Profiler）
=====================

你可以開啟 MongoDB 的紀錄檢視功能，執行：

::

    db.setProfilingLevel(2);

開啟之後，再執行一個指令：

::

    db.unicorns.find({weight: {$gt: 600}});

接著查看檢視器的記錄：

::

    db.system.profile.find()

輸出結果將會告訴我們，在什麼時間執行過哪些指令、\
有多少文件被掃描過，以及回傳多少資料。

你可以再次呼叫 ``setProfileLevel`` 並將參數修改成 ``0``\ ，
就可以將記錄檢視的功能關閉。\
也可以將它修改成 ``1``\ ，\
這個數字代表只有執行時間超過 100 毫秒的指令才會被記錄，\
如果你想要指定這個時間門檻，\
可以用第二個參數：

::

    //只有執行時間超過1秒的指令會被記錄
    db.setProfilingLevel(1, 1000);

備份與還原
==========

在 MongoDB 的 ``bin`` 資料夾中，\
有一個 ``mongodump`` 程式，\
直接執行這個程式，\
就會連接到本地資料庫伺服器，\
並將所有資料庫備份到 ``dump`` 這個子資料夾中。\
使用 ``mongodump --help`` 可以查看額外的選項，\
其中常用的選項有 ``--db DBNAME`` 用來備份指定的資料庫，\
以及 ``--collection COLLECTIONNAME`` 用來備份指定的資料集合。\
同樣在 ``bin`` 資料夾中還有 ``mongorestore`` 程式，\
可以之前備份的資料還原，\
它同樣也提供 ``--db`` 及 ``--collection`` 參數。

舉例來說，如果我們要備份 ``learn`` 資料集合到 ``backup`` 資料夾，\
可以執行（請注意這是在系統終端機下執行，而不是 mongo shell）：

::

    mongodump --db learn --out backup

當我們只想要還原 ``unicorns`` 資料集合，可以這麼做：

::

    mongorestore --collection unicorns backup/learn/unicorns.bson

值得一提的還有 ``mongoexport`` 及 ``mongoimport`` 兩個工具，\
它們可以用來匯出及匯入資料，並支援 JSON 與 CSV 兩種格式。\
舉例來說，我們可以用以下指令將資料集合匯出成 JSON 文字檔。

::

    mongoexport --db learn -collection unicorns

這是匯出成 CSV 格式的範例：

::

    mongoexport --db learn -collection unicorns --csv -fields name,weight,vampires

請注意 ``mongoexport`` 及 ``mongoimport`` 並無法呈現完整的資料，
只有 ``mongodump`` 及 ``mongorestore`` 才適合用來真正備份資料。

重點回顧
========

我們使用 MongoDB 的數個指令及工具，\
還有討論效能的主題。\
雖然無法涵蓋所有東西，\
但我們確實已經將最常見的部分講完。\
MongoDB 的索引和關聯式資料庫非常相似，\
也提供許多重要的工具，\
大多數使用起來相當容易。

