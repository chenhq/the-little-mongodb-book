********
開始入門
********

這本書大部分將專注在 MongoDB 主要的核心功能，\
所以我們使用 MongoDB 的純文字使用者交互介面（shell）。\
雖然這個介面很適合用於學習過程，\
也是個相當有用的管理工具；\
但是在你實際撰寫的程式碼，\
將會需要使用一個 MongoDB 的驅動程式（driver）。

這是你開始認識 MongoDB 所需要知道的地一件事。\
MongoDB 提供多種\
`官方驅動程式 <http://www.mongodb.org/display/DOCS/Drivers>`_\
給不同的程式語言。\
這些驅動程式和你已經熟悉的其他資料庫類似。\
在這些驅動程式之上，\
開發社群為不同程式語言或開發框架建立特定的函式庫，\
例如 `NoRM <https://github.com/atheken/NoRM>`_
就是 C# （LINQ實作）的函式庫；\
而 `MongoMapper <https://github.com/jnunemaker/mongomapper>`_
則是 Ruby （適用於 ActiveRecord）的函式庫。\
你可以選擇直接使用核心的 MongoDB 驅動程式，\
或者使用某些高階的函式庫；\
但這些將不在本書的討論範圍內，\
因為 MongoDB 的新手可能會被官方驅動程式及社群函式庫給混淆\
（前者是直接溝通與連接到 MongoDB，\
後者則是針對特定程式語言或開發框架的實作）。

我鼓勵讀者現在就開始使用 MongoDB，\
動手執行這本書的範例，\
探索你可能碰到的問題。\
安裝和執行 MongoDB 非常簡單，\
我們現在就花幾分鐘時間搞定它吧！

1. 打開 `官方下載頁面 <http://www.mongodb.org/downloads>`_\ ，\
   根據你的作業系統類型，\
   取得建議穩定版本的執行檔（the recommended stable version）。\
   對於開發用途來說，你可以任意選擇32位元或64位元版本。

2. 解開壓縮檔之後，瀏覽底下的 ``bin`` 子目錄，\
   先別急著執行任何程式。\
   你需要瞭解 ``mongod`` 是伺服器程式，\
   而 ``mongo`` 則是客戶端工具。\
   我們大部分的時間都會用到這兩個程式。

3. 在 ``bin`` 目錄中建立一個文字檔案，命名為 ``mongodb.config``

4. 在 mongodb.config 加入一行設定，\
   ``dbpath=PATH_TO_WHERE_YOU_WANT_TO_STORE_YOUR_DATABASE_FILES`` 。\
   舉例來說，如果你使用視窗作業系統（Windows），\
   就可以設定為 ``dbpath=c:\mongodb\data`` ，
   而 Linux 系統則可能是 ``dbpath=/etc/mongodb/data`` 。

5. 請確定 ``dbpath`` 指定的路徑確實存在。

6. 執行 mongod 並指定參數 ``--config /path/to/your/mongodb.config`` 。

以 Windows 的使用者為例，\
如果你將檔案解壓縮到 ``c:\mongodb\`` ，\
並且也建立 ``c:\mongodb\data\`` 資料夾，\
那麼在 ``c:\mongodb\bin\mongodb.config`` 文字檔案中，\
就可以設定 ``dbpath=c:\mongodb\data\`` 。\
您如果要執行 ``mongod`` 程式，\
可以在「開始、執行」中輸入
``c:\mongodb\bin\mongod --config c:\mongodb\bin\mongodb.config`` 。

將 ``bin`` 的路徑加入到 path 系統環境變數，\
可以讓執行的時候不必打入完整的路徑。\
MacOSX 及 Linux 的使用者可以依照系統慣例安置檔案，\
只要把改變這些檔案的路徑即可。

希望你的 MongoDB 已經安裝、執行成功，\
如果出現錯誤，\
請仔細閱讀輸出訊息，\
就可以瞭解發生什麼事情。

現在就可以執行 ``mongo``\ （請注意沒有\ *d*\ 字元），\
它會連線到目前正在執行的伺服器，\
試著輸入 ``db.version()`` 確認一切正常無誤。\
希望你可以看到版本訊息，那代表你安裝的版本，以及到目前為止都很順利。


