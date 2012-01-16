********
修改資料
********

在前一章我們介紹 CRUD（create, read, update, delete）的其中3個運算子，\
這一章則專門介紹我們跳過的 ``updated`` ，\
這個運算子有些難以想像的用途，\
所以需要特別寫成一章介紹它。

修改：整筆取代及 $set 修飾器
============================

``update`` 最簡單的用法，只需要2個參數：運算子（where）及需要更新的欄位資料。\
例如 Roooooodles 的體重增加一些，我們可以執行：

::

    db.unicorns.update({name: 'Roooooodles'}, {weight: 590})

（如果你的 ``unicorns`` 資料集合被玩毀了，\
請執行 ``remove`` 指令清除，\並且重新執行第一章提供的新增測試資料語法。）

在你真正開始設計程式時，\
請利用 ``_id`` 當條件來選擇資料；\
因為我無從得知 MongoDB 幫你產生的 ``_id`` 之值為何，\
所以我們暫且使用 ``name`` 欄位。\
如果上個步驟執行完成，可以檢視一下結果：

::

    db.unicorns.find({name: 'Roooooodles'})

你應該感覺很訝異，因為結果並沒有找到任何文件。\
因為 ``update`` 的第二個參數將原本的資料\ **覆蓋**\ 掉，\
換句話說，\ ``update`` 利用 ``name`` 找到文件後，\
會將整個文件取代成新的文件（第二個參數），\
這和 SQL 的 ``update`` 指令作用並不相同。\
對某些情況來說，這是理想的作法，可以應付真正動態修改的需要，\
然而，當你只想要修改一個或少數幾個欄位的值，\
最好的方法就是使用 MongoDB 的 ``$set`` 修飾器（modifier）。

::

    db.unicorns.update({weight: 590}, {$set: {
        name: 'Roooooodles', dob: new Date(1979, 7, 18, 18, 44),
        loves: ['apple'], gender: 'm', vampires: 99}})

上面這段程式會重設先前遺失的欄位，但是不會覆蓋新設定的 ``weight`` 欄位，\
除非你特別指定它。\
現在我們可以執行：

::

    db.unicorns.find({name: 'Roooooodles'})

這次我們可以的得到預期的結果，\
因此，如果我們只是想修改體重欄位，\
其實只需要在一開始就這麼做：

::

    db.unicorns.update({name: 'Roooooodles'}, {$set: {weight: 590}})

修改資料的修飾器
================

除了 ``$set`` 我們還有其它管用的修飾器，\
這些修飾器只會對欄位進行修改，\
而不會消滅整筆文件（document）。\
例如\ ``$inc`` 修飾器可以用來加或減指定的數字。\
假設 Pilot 獨角獸消滅吸血鬼的數量多了一對，\
我們就可以執行以下的程式來修正問題：

::

    db.unicorns.update({name: 'Pilot'}, {$inc: {vampires: -2}})

如果獨角獸 Aurora 長出可愛的牙齒，\
我們可以透過 ``$push`` 修飾器增加一個值到 ``loves`` 欄位。

::

    db.unicorns.update({name: 'Aurora'}, {$push: {loves: 'sugar'}})

MongoDB 網站提供的\ `修改資料 <http://www.mongodb.org/display/DOCS/Updating>`_\
文件，有更多關於修飾器的資訊。

自動判斷修改或新增（upserts）
============================

``update`` 令人驚喜的地方，\
還包括它完整支援 ``upserts`` 用法。\
``upsert`` 就是當被修改的文件（document）不存在時，\
會自動新增這一筆文件，對許多情況來說相當管用，\
當你遇到的時候自然就會明白。\
想要開啟這個功能，只需要在 ``update`` 的第三個參數指定 ``true`` 。

再普通不過的例子，就是網站的頁面瀏覽次數計數器，\
如果我們想要保持總數量的即時更新，\
我們要先檢查某個頁面的計數資料是否存在，\
然後才決定要執行修改（update）或是新增（insert）。\
如果 ``update`` 的第三個參數不存在（或設定成 false），\
執行以下的程式就不會修改任何東西：

::

    db.hits.update({page: 'unicorns'}, {$inc: {hits: 1}});
    db.hits.find();

然而，如果打開自動判斷（upsert）功能，執行結果就會完全不同：

::

    db.hits.update({page: 'unicorns'}, {$inc: {hits: 1}}, true);
    db.hits.find();

由於 ``hits`` 並不存在 ``page`` 欄位值為 ``unicorns`` 的文件，\
所以會自動產生一筆新文件存入。\
如果再執行一次，就會發現數字被增加為2。

::

    db.hits.update({page: 'unicorns'}, {$inc: {hits: 1}}, true);
    db.hits.find();

一次修改多筆資料
================

最後 ``update`` 還有個讓人訝異的地方，\
就是它預設只會修改一筆文件，\
雖然前面的例子，\
只修改一筆文件很合乎邏輯，\
但是，如果你執行類似以下的程式：

::

    db.unicorns.update({}, {$set: {vaccinated: true }});
    db.unicorns.find({vaccinated: true});

你可能會預期所有獨角獸都被設定成已接踵疫苗（vaccinated），\
但其實只更新其中一筆。\
如果你想要一次修改全部，
就必須將 ``update`` 的第四個參數設定成 true。

::

    db.unicorns.update({}, {$set: {vaccinated: true }}, false, true);
    db.unicorns.find({vaccinated: true});

重點回顧
========

本章我們已看過資料集合可用的基本 CRUD 操作，\
我們更進一步學習 ``update`` 及它的三個有趣行為。\
首先，和 SQL 的 update 不同的地方，\
MongoDB 的 ``update`` 會把整個舊資料覆蓋，\
因此瞭解 ``$set`` 修飾器很重要。\
第二，\ ``update`` 支援 ``upsert`` 的用法，\
搭配 ``$inc`` 修飾器在某些情況下很管用。\
最後，預設情況下 ``update`` 只會更新它找到的第一筆資料。

記得在學習過程中我們只把重點放在 MongoDB 提供的 shell 功能，\
在實際設計程式時，\
根據你所選擇的驅動程式或函式庫，\
你可以修改這些預設行為，\
或使用不同的 API 設計。\
舉例來說，Ruby 的驅動程式將 ``update`` 最後兩個參數，\
變成一個 hash 設定： ``{:upsert => false, :multi => false}`` 。

