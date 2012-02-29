**********
MapReduce
**********

MapReduce 是一種資料處理的方法，\
比起較傳統的作法，\
它有兩個象徵性的好處。\
第一個也是主要的理由，\
就是它的發展是為了效能，\
理論上，MapReduce 可以平行處理，\
允許經由多顆核心、處理器或機器來處理非常大的資料集合，\
就像我們已經提過的，\
你還可以從 MongoDB 獲得其他好處。\
MapReduce 的第二個好處，\
就是允許你為處理程序撰寫實際的程式碼。\
和你可以使用 SQL 做的事情相比，\
MapReduce 程式碼有無限豐富的應用，\
當你需要更特別的解決方案時，\
它或許就能派上用場。

MapReduce 已經是愈來愈熱門的資料處理模式，\
你幾乎可以將它用在任何地方，像是 C#、Ruby、Java、Python 及其他的實作。\
我需要先告誡你的是，\
這種作法很不一樣也很複雜，\
先別沮喪，用點時間自己動手玩玩看，\
這相當值得用於瞭解你是否要使用 MongoDB。

結合理論與實務
============

MapReduce 的處理程序共有兩個步驟，\
首先你需要先做映射（map）再做化簡（reduce），\
映射的步驟將輸入的資料轉換，並建立 key-value pair（key 或 value 可以很複雜）；\
化簡取得 key 和 value 的陣列，並且對 key 產生最後處理的結果。\
接下來我們會看看每個步驟，以及每個步驟的輸出。

這個範例是我們將資源（就是網頁）每天的點擊次數產生成報表，\
這是 MapReduce 的\ *hello world*\ 。\
為達到這個目的，我們使用 ``hits`` 資料集合，\
它包含兩個欄位：\ ``resource`` 和 ``date``\ 。\
我們想得到的輸出結果包含 ``resource``\ 、\ ``year``\ 、\ ``month``\ 、\ ``day`` 及 ``count``\ 。

假設 ``hits`` 集合有以下的資料:

::

    resource     date
    index        Jan 20 2010 4:30
    index        Jan 20 2010 5:30
    about        Jan 20 2010 6:00
    index        Jan 20 2010 7:00
    about        Jan 21 2010 8:00
    about        Jan 21 2010 8:30
    index        Jan 21 2010 8:30
    about        Jan 21 2010 9:00
    index        Jan 21 2010 9:30
    index        Jan 22 2010 5:00

我們預期會有以下輸出：

::

    resource  year   month   day   count
    index     2010   1       20    3
    about     2010   1       20    1
    about     2010   1       21    3
    index     2010   1       21    2
    index     2010   1       22    1

用這種方法來分析資料，最棒的事情就是輸出的保存，\
報表可以很快產生，並且資料量的增長可以被控制。\
（依照我們的記錄，每天最多只會增加一筆文件。）

在開始之前，先專注在瞭解這個概念，\
本章最後的範例資料和程式碼，可以讓你自己動手試試看。

你需要做的第一件事情，就是看一下 map 函式，\
map 目的是要建立能夠被化簡的值，\
map 可能被發送（emit） 0 或多次，\
在我們的案例中，\
它永遠只會被發送 1 次（這是常見的情況）。\
將 map 想像成在 ``hits`` 集合處理每一筆文件的迴圈，\
對於每筆文件，我們發送包含 resource、year、month、day 的 key，\
以及將 value 簡單地設為 1。

::

    function() {
        var key = {
            resource: this.resource, 
            year: this.date.getFullYear(), 
            month: this.date.getMonth(), 
            day: this.date.getDate()
        };
        emit(key, {count: 1}); 
    }

``this`` 參考到目前正在處理的文件。\
希望映射的輸出結果可以幫助你瞭解，\
參考以下的資料，這是所有完整的輸出。

::

    {resource: 'index', year: 2010, month: 0, day: 20} => [{count: 1}, {count: 1}, {count:1}]
    {resource: 'about', year: 2010, month: 0, day: 20} => [{count: 1}]
    {resource: 'about', year: 2010, month: 0, day: 21} => [{count: 1}, {count: 1}, {count:1}]
    {resource: 'index', year: 2010, month: 0, day: 21} => [{count: 1}, {count: 1}]
    {resource: 'index', year: 2010, month: 0, day: 22} => [{count: 1}]

瞭解中間的步驟，是你理解 MapReduce 的關鍵，\
被發送的值會被群組化，\
根據 key 產生陣列資料。\
.NET 或 Java 開發者可以把它想成以下的型別定義：
``IDictionary<object, IList<object>>``\ （.NET）或是\
``HashMap<Object, ArrayList>``\ （Java）。

讓我們用比較不自然的方法修改這個函式：

::

    function() {
        var key = {resource: this.resource, year: this.date.getFullYear(), month: this.date.getMonth(), day: this.date.getDate()};
        if (this.resource == 'index' && this.date.getHours() == 4) {
            emit(key, {count: 5});
        } else {
            emit(key, {count: 1}); 
        }
    }

第一筆輸出會變成：

::

    {resource: 'index', year: 2010, month: 0, day: 20} => [{count: 5}, {count: 1}, {count:1}]

請注意每次發送產生新的值，都會根據 key 分群。

化簡函式會取得這些中間的階段結果，並產生最終結果。\
以下是我們使用的程式碼：

::

    function(key, values) {
        var sum = 0;
        values.forEach(function(value) {
            sum += value['count'];
        });
        return {count: sum};
    };

這段程式將會輸出：

::

    {resource: 'index', year: 2010, month: 0, day: 20} => {count: 3}
    {resource: 'about', year: 2010, month: 0, day: 20} => {count: 1}
    {resource: 'about', year: 2010, month: 0, day: 21} => {count: 3}
    {resource: 'index', year: 2010, month: 0, day: 21} => {count: 2}
    {resource: 'index', year: 2010, month: 0, day: 22} => {count: 1}

就技術上來說，在 MongoDB 的輸出是：

::

    _id: {resource: 'home', year: 2010, month: 0, day: 20}, value: {count: 3}

希望你已經注意到，這就是我們之後的最終結果。

如果你很認真看這個範例，你可能會有個疑問：\
為何我們不簡單地使用 ``sum = values.length`` 呢？\
既然陣列的值都是 1，那麼計算陣列的資料筆數不是更有效率的方法嗎？\
事實上化簡並非每次都會得到完整的階段資料，\
舉例來說，假設有以下的資料需要化簡：

::

    {resource: 'home', year: 2010, month: 0, day: 20} => [{count: 1}, {count: 1}, {count:1}]

化簡實際上可能被這樣呼叫：

::

    {resource: 'home', year: 2010, month: 0, day: 20} => [{count: 1}, {count: 1}]
    {resource: 'home', year: 2010, month: 0, day: 20} => [{count: 2}, {count: 1}]

最後的結果仍然相同（3），但取得這個結果的過程卻不一樣，\
所以，化簡必須等冪，\
也就是說不管分成幾次呼叫化簡，都必須跟只呼叫一次有相同計算結果。

雖然我們在這裡不會提供更多的範例，\
但是對於更複雜的分析來說，\
這仍是化簡的的共通原則。

純實務
=====

在 MongoDB 我們對資料集合（collection）使用 ``mapReduce`` 指令，\
``mapReduce`` 需要傳入 map 函式、reduce 函式及一個輸出指令，\
我們在 shell 可以建立並傳遞一個 JavaScript 函式，\
對多數的函式庫來說，你需要將函數用字串方式傳入（有點醜陋）。\
第一件事，讓我們建立這個簡單的資料集：

::

    db.hits.insert({resource: 'index', date: new Date(2010, 0, 20, 4, 30)});
    db.hits.insert({resource: 'index', date: new Date(2010, 0, 20, 5, 30)});
    db.hits.insert({resource: 'about', date: new Date(2010, 0, 20, 6, 0)});
    db.hits.insert({resource: 'index', date: new Date(2010, 0, 20, 7, 0)});
    db.hits.insert({resource: 'about', date: new Date(2010, 0, 21, 8, 0)});
    db.hits.insert({resource: 'about', date: new Date(2010, 0, 21, 8, 30)});
    db.hits.insert({resource: 'index', date: new Date(2010, 0, 21, 8, 30)});
    db.hits.insert({resource: 'about', date: new Date(2010, 0, 21, 9, 0)});
    db.hits.insert({resource: 'index', date: new Date(2010, 0, 21, 9, 30)});
    db.hits.insert({resource: 'index', date: new Date(2010, 0, 22, 5, 0)});

現在我們可以建立 map 及 reduce 函式\
（MongoDB 的 shell 允許一次輸入多行的代碼，\
在按下 Enter 後會看到 *...* 的提示，你可以輸入更多文字）：

::

    var map = function() {
        var key = {resource: this.resource, year: this.date.getFullYear(), month: this.date.getMonth(), day: this.date.getDate()};
        emit(key, {count: 1}); 
    };

    var reduce = function(key, values) {
        var sum = 0;
        values.forEach(function(value) {
            sum += value['count'];
        });
        return {count: sum};
    };

我們可以對 ``hits`` 資料集合使用 ``mapReduce`` 指令：

::

    db.hits.mapReduce(map, reduce, {out: {inline:1}})

如果你執行上面的程式，你就會看到輸出結果。\
將 ``out`` 設定為 ``inline`` 表示將 ``mapReduce`` 的輸出結果直接傳回，\
輸出結果目前有 16MB 容量的限制。\
我們也可以指定``{out: 'hit_stats'}`` 讓結果保存在 ``hit_stats`` 資料集合。

::

    db.hits.mapReduce(map, reduce, {out: 'hit_stats'});
    db.hit_stats.find();

如果你這樣做，在 ``hit_stats`` 的現有資料將會遺失，\
我們也可以改用 ``{out: {merge: 'hit_stats'}}`` 讓資料以新增或更新文件的方式保存。\
最後一種方法，就是我們可以用 ``reduce`` 函式來處理更進階的情況（像是做 upsert）。

第三個參數還有其他選項可用，例如我們可以對分析結果的文件做篩選、排序或限制筆數。\
我們也可以提供一個 ``finalize`` 方法，在 ``reduce`` 完成後對結果進行運算處理。

重點回顧
=======

本章的內容和傳統資料庫觀念差異較大，\
如果這讓你感到還無法適應，\
請記得你也可以只用 MongoDB 的
`aggregation capabilities <http://www.mongodb.org/display/DOCS/Aggregation>`_
處理一般狀況。\
最後需要思考的，\
MapReduce 是讓 MongoDB 名聲響亮的功能之一，\
要真正瞭解如何撰寫 map 及 reduce 函式的關鍵，\
就是透過由 ``map`` 到 ``reduce`` 過程中的資料。
