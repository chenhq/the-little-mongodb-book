*******************
這樣用 MongoDB 就對了
*******************

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
~~~~~~~~~~~

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

Writes
~~~~~~

One area where MongoDB can fit a specialized role is in logging. There
are two aspects of MongoDB which make writes quite fast. First, you can
send a write command and have it return immediately without waiting for
it to actually write. Secondly, with the introduction of journaling in
1.8, and enhancements made in 2.0, you can control the write behavior
with respect to data durability. These settings, in addition to
specifying how many servers should get your data before being considered
successful, are configurable per-write, giving you a great level of
control over write performance and data durability.

In addition to these performance factors, log data is one of those data
sets which can often take advantage of schema-less collections. Finally,
MongoDB has something called a `capped
collection <http://www.mongodb.org/display/DOCS/Capped+Collections>`_.
So far, all of the implicitly created collections we've created are just
normal collections. We can create a capped collection by using the
``db.createCollection`` command and flagging it as capped:

::

    //limit our capped collection to 1 megabyte
    db.createCollection('logs', {capped: true, size: 1048576})

When our capped collection reaches its 1MB limit, old documents are
automatically purged. A limit on the number of documents, rather than
the size, can be set using ``max``. Capped collections have some
interesting properties. For example, you can update a document but it
can't grow in size. Also, the insertion order is preserved, so you don't
need to add an extra index to get proper time-based sorting.

This is a good place to point out that if you want to know whether your
write encountered any errors (as opposed to the default
fire-and-forget), you simply issue a follow-up command:
``db.getLastError()``. Most drivers encapsulate this as a *safe write*,
say by specifying ``{:safe => true}`` as a second parameter to
``insert``.

Durability
~~~~~~~~~~

Prior to version 1.8, MongoDB didn't have single-server durability. That
is, a server crash would likely result in lost data. The solution had
always been to run MongoDB in a multi-server setup (MongoDB supports
replication). One of the major features added to 1.8 was journaling. To
enable it add a new line with ``journal=true`` to the ``mongodb.config``
file we created when we first setup MongoDB (and restart your server if
you want it enabled right away). You probably want journaling enabled
(it'll be a default in a future release). Although, in some
circumstances the extra throughput you get from disabling journaling
might be a risk you are willing to take. (It's worth pointing out that
some types of applications can easily afford to lose data).

Durability is only mentioned here because a lot has been made around
MongoDB's lack of single-server durability. This'll likely show up in
Google searches for some time to come. Information you find about this
missing feature is simply out of date.

Full Text Search
~~~~~~~~~~~~~~~~

True full text search capability is something that'll hopefully come to
MongoDB in a future release. With its support for arrays, basic full
text search is pretty easy to implement. For something more powerful,
you'll need to rely on a solution such as Lucene/Solr. Of course, this
is also true of many relational databases.

Transactions
~~~~~~~~~~~~

MongoDB doesn't have transactions. It has two alternatives, one which is
great but with limited use, and the other that is a cumbersome but
flexible.

The first is its many atomic operations. These are great, so long as
they actually address your problem. We already saw some of the simpler
ones, like ``$inc`` and ``$set``. There are also commands like
``findAndModify`` which can update or delete a document and return it
atomically.

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

Data Processing
~~~~~~~~~~~~~~~

MongoDB relies on MapReduce for most data processing jobs. It has some
`basic aggregation <http://www.mongodb.org/display/DOCS/Aggregation>`_
capabilities, but for anything serious, you'll want to use MapReduce. In
the next chapter we'll look at MapReduce in detail. For now you can
think of it as a very powerful and different way to ``group by`` (which
is an understatement). One of MapReduce's strengths is that it can be
parallelized for working with large sets of data. However, MongoDB's
implementation relies on JavaScript which is single-threaded. The point?
For processing of large data, you'll likely need to rely on something
else, such as Hadoop. Thankfully, since the two systems really do
complement each other, there's a `MongoDB adapter for
Hadoop <https://github.com/mongodb/mongo-hadoop>`_.

Of course, parallelizing data processing isn't something relational
databases excel at either. There are plans for future versions of
MongoDB to be better at handling very large sets of data.

Geospatial
~~~~~~~~~~

A particularly powerful feature of MongoDB is its support for geospatial
indexes. This allows you to store x and y coordinates within documents
and then find documents that are ``$near`` a set of coordinates or
``$within`` a box or circle. This is a feature best explained via some
visual aids, so I invite you to try the `5 minute geospatial interactive
tutorial <http://mongly.com/geo/index>`_, if you want to learn more.

Tools and Maturity
~~~~~~~~~~~~~~~~~~

You probably already know the answer to this, but MongoDB is obviously
younger than most relational database systems. This is absolutely
something you should consider. How much a factor it plays depends on
what you are doing and how you are doing it. Nevertheless, an honest
assessment simply can't ignore the fact that MongoDB is younger and the
available tooling around isn't great (although the tooling around a lot
of very mature relational databases is pretty horrible too!). As an
example, the lack of support for base-10 floating point numbers will
obviously be a concern (though not necessarily a show-stopper) for
systems dealing with money.

On the positive side, drivers exist for a great many languages, the
protocol is modern and simple, and development is happening at blinding
speeds. MongoDB is in production at enough companies that concerns about
maturity, while valid, are quickly becoming a thing of the past.

重點回顧
=======

The message from this chapter is that MongoDB, in most cases, can
replace a relational database. It's much simpler and straightforward;
it's faster and generally imposes fewer restrictions on application
developers. The lack of transactions can be a legitimate and serious
concern. However, when people ask *where does MongoDB sit with respect
to the new data storage landscape?* the answer is simple: **right in the
middle**.
