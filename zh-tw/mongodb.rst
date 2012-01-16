Chapter 3 - Mastering Find
--------------------------

Chapter 1 provided a superficial look at the ``find`` command. There's
more to ``find`` than understanding ``selectors`` though. We already
mentioned that the result from ``find`` is a ``cursor``. We'll now look
at exactly what this means in more detail.

Field Selection
~~~~~~~~~~~~~~~

Before we jump into ``cursors``, you should know that ``find`` takes a
second optional parameter. This parameter is the list of fields we want
to retrieve. For example, we can get all of the unicorns names by
executing:

::

    db.unicorns.find(null, {name: 1});

By default, the ``_id`` field is always returned. We can explicitly
exclude it by specifying ``{name:1, _id: 0}``.

Aside from the ``_id`` field, you cannot mix and match inclusion and
exclusion. If you think about it, that actually makes sense. You either
want to select or exclude one or more fields explicitly.

Ordering
~~~~~~~~

A few times now I've mentioned that ``find`` returns a cursor whose
execution is delayed until needed. However, what you've no doubt
observed from the shell is that ``find`` executes immediately. This is a
behavior of the shell only. We can observe the true behavior of
``cursors`` by looking at one of the methods we can chain to ``find``.
The first that we'll look at is ``sort``. ``sort`` works a lot like the
field selection from the previous section. We specify the fields we want
to sort on, using 1 for ascending and -1 for descending. For example:

::

    //heaviest unicorns first
    db.unicorns.find().sort({weight: -1})

    //by vampire name then vampire kills:
    db.unicorns.find().sort({name: 1, vampires: -1})

Like with a relational database, MongoDB can use an index for sorting.
We'll look at indexes in more detail later on. However, you should know
that MongoDB limits the size of your sort without an index. That is, if
you try to sort a large result set which can't use an index, you'll get
an error. Some people see this as a limitation. In truth, I wish more
databases had the capability to refuse to run unoptimized queries. (I
won't turn every MongoDB drawback into a positive, but I've seen enough
poorly optimized databases that I sincerely wish they had a
strict-mode.)

Paging
~~~~~~

Paging results can be accomplished via the ``limit`` and ``skip`` cursor
methods. To get the second and third heaviest unicorn, we could do:

::

    db.unicorns.find().sort({weight: -1}).limit(2).skip(1)

Using ``limit`` in conjunction with ``sort``, is a good way to avoid
running into problems when sorting on non-indexed fields.

Count
~~~~~

The shell makes it possible to execute a ``count`` directly on a
collection, such as:

::

    db.unicorns.count({vampires: {$gt: 50}})

In reality, ``count`` is actually a ``cursor`` method, the shell simply
provides a shortcut. Drivers which don't provide such a shortcut need to
be executed like this (which will also work in the shell):

::

    db.unicorns.find({vampires: {$gt: 50}}).count()

In This Chapter
~~~~~~~~~~~~~~~

Using ``find`` and ``cursors`` is a straightforward proposition. There
are a few additional commands that we'll either cover in later chapters
or which only serve edge cases, but, by now, you should be getting
pretty comfortable working in the mongo shell and understanding the
fundamentals of MongoDB.

Chapter 4 - Data Modeling
-------------------------

Let's shift gears and have a more abstract conversation about MongoDB.
Explaining a few new terms and some new syntax is a trivial task. Having
a conversation about modeling with a new paradigm isn't as easy. The
truth is that most of us are still finding out what works and what
doesn't when it comes to modeling with these new technologies. It's a
conversation we can start having, but ultimately you'll have to practice
and learn on real code.

Compared to most NoSQL solutions, document-oriented databases are
probably the least different, compared to relational databases, when it
comes to modeling. The differences which exist are subtle but that
doesn't mean they aren't important.

No Joins
~~~~~~~~

The first and most fundamental difference that you'll need to get
comfortable with is MongoDB's lack of joins. I don't know the specific
reason why some type of join syntax isn't supported in MongoDB, but I do
know that joins are generally seen as non-scalable. That is, once you
start to horizontally split your data, you end up performing your joins
on the client (the application server) anyways. Regardless of the
reasons, the fact remains that data *is* relational, and MongoDB doesn't
support joins.

Without knowing anything else, to live in a join-less world, we have to
do joins ourselves within our application's code. Essentially we need to
issue a second query to ``find`` the relevant data. Setting our data up
isn't any different than declaring a foreign key in a relational
database. Let's give a little less focus to our beautiful ``unicorns``
and a bit more time to our ``employees``. The first thing we'll do is
create an employee (I'm providing an explicit ``_id`` so that we can
build coherent examples)

::

    db.employees.insert({_id: ObjectId("4d85c7039ab0fd70a117d730"), name: 'Leto'})

Now let's add a couple employees and set their manager as ``Leto``:

::

    db.employees.insert({_id: ObjectId("4d85c7039ab0fd70a117d731"), name: 'Duncan', manager: ObjectId("4d85c7039ab0fd70a117d730")});
    db.employees.insert({_id: ObjectId("4d85c7039ab0fd70a117d732"), name: 'Moneo', manager: ObjectId("4d85c7039ab0fd70a117d730")});

(It's worth repeating that the ``_id`` can be any unique value. Since
you'd likely use an ``ObjectId`` in real life, we'll use them here as
well.)

Of course, to find all of Leto's employees, one simply executes:

::

    db.employees.find({manager: ObjectId("4d85c7039ab0fd70a117d730")})

There's nothing magical here. In the worst cases, most of the time, the
lack of join will merely require an extra query (likely indexed).

Arrays and Embedded Documents
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Just because MongoDB doesn't have joins doesn't mean it doesn't have a
few tricks up its sleeve. Remember when we quickly saw that MongoDB
supports arrays as first class objects of a document? It turns out that
this is incredibly handy when dealing with many-to-one or many-to-many
relationships. As a simple example, if an employee could have two
managers, we could simply store these in an array:

::

    db.employees.insert({_id: ObjectId("4d85c7039ab0fd70a117d733"), name: 'Siona', manager: [ObjectId("4d85c7039ab0fd70a117d730"), ObjectId("4d85c7039ab0fd70a117d732")] })

Of particular interest is that, for some documents, ``manager`` can be a
scalar value, while for others it can be an array. Our original ``find``
query will work for both:

::

    db.employees.find({manager: ObjectId("4d85c7039ab0fd70a117d730")})

You'll quickly find that arrays of values are much more convenient to
deal with than many-to-many join-tables.

Besides arrays, MongoDB also supports embedded documents. Go ahead and
try inserting a document with a nested document, such as:

::

    db.employees.insert({_id: ObjectId("4d85c7039ab0fd70a117d734"), name: 'Ghanima', family: {mother: 'Chani', father: 'Paul', brother: ObjectId("4d85c7039ab0fd70a117d730")}})

In case you are wondering, embedded documents can be queried using a
dot-notation:

::

    db.employees.find({'family.mother': 'Chani'})

We'll briefly talk about where embedded documents fit and how you should
use them.

DBRef
^^^^^

MongoDB supports something known as ``DBRef`` which is a convention many
drivers support. When a driver encounters a ``DBRef`` it can
automatically pull the referenced document. A ``DBRef`` includes the
collection and id of the referenced document. It generally serves a
pretty specific purpose: when documents from the same collection might
reference documents from a different collection from each other. That
is, the ``DBRef`` for document1 might point to a document in
``managers`` whereas the ``DBRef`` for document2 might point to a
document in ``employees``.

Denormalization
^^^^^^^^^^^^^^^

Yet another alternative to using joins is to denormalize your data.
Historically, denormalization was reserved for performance-sensitive
code, or when data should be snapshotted (like in an audit log).
However, with the ever-growing popularity of NoSQL, many of which don't
have joins, denormalization as part of normal modeling is becoming
increasingly common. This doesn't mean you should duplicate every piece
of information in every document. However, rather than letting fear of
duplicate data drive your design decisions, consider modeling your data
based on what information belongs to what document.

For example, say you are writing a forum application. The traditional
way to associate a specific ``user`` with a ``post`` is via a ``userid``
column within ``posts``. With such a model, you can't display ``posts``
without retrieving (joining to) ``users``. A possible alternative is
simply to store the ``name`` as well as the ``userid`` with each
``post``. You could even do so with an embedded document, like
``user: {id: ObjectId('Something'), name: 'Leto'}``. Yes, if you let
users change their name, you'll have to update each document (which is 1
extra query).

Adjusting to this kind of approach won't come easy to some. In a lot of
cases it won't even make sense to do this. Don't be afraid to experiment
with this approach though. It's not only suitable in some circumstances,
but it can also be the right way to do it.

Which Should You Choose?
^^^^^^^^^^^^^^^^^^^^^^^^

Arrays of ids are always a useful strategy when dealing with one-to-many
or many-to-many scenarios. It's probably safe to say that ``DBRef``
aren't use very often, though you can certainly experiment and play with
them. That generally leaves new developers unsure about using embedded
documents versus doing manual referencing.

First, you should know that an individual document is currently limited
to 4 megabytes in size. Knowing that documents have a size limit, though
quite generous, gives you some idea of how they are intended to be used.
At this point, it seems like most developers lean heavily on manual
references for most of their relationships. Embedded documents are
frequently leveraged, but mostly for small pieces of data which we want
to always pull with the parent document. A real world example I've used
is to store an ``accounts`` document with each user, something like:

::

    db.users.insert({name: 'leto', email: 'leto@dune.gov', account: {allowed_gholas: 5, spice_ration: 10}})

That doesn't mean you should underestimate the power of embedded
documents or write them off as something of minor utility. Having your
data model map directly to your objects makes things a lot simpler and
often does remove the need to join. This is especially true when you
consider that MongoDB lets you query and index fields of an embedded
document.

Few or Many Collections
~~~~~~~~~~~~~~~~~~~~~~~

Given that collections don't enforce any schema, it's entirely possible
to build a system using a single collection with a mismatch of
documents. From what I've seen, most MongoDB systems are laid out
similarly to what you'd find in a relational system. In other words, if
it would be a table in a relational database, it'll likely be a
collection in MongoDB (many-to-many join tables being an important
exception).

The conversation gets even more interesting when you consider embedded
documents. The example that frequently comes up is a blog. Should you
have a ``posts`` collection and a ``comments`` collection, or should
each ``post`` have an array of ``comments`` embedded within it. Setting
aside the 4MB limit for the time being (all of Hamlet is less than
200KB, just how popular is your blog?), most developers still prefer to
separate things out. It's simply cleaner and more explicit.

There's no hard rule (well, aside from 4MB). Play with different
approaches and you'll get a sense of what does and does not feel right.

In This Chapter
~~~~~~~~~~~~~~~

Our goal in this chapter was to provide some helpful guidelines for
modeling your data in MongoDB. A starting point if you will. Modeling in
a document-oriented system is different, but not too different than a
relational world. You have a bit more flexibility and one constraint,
but for a new system, things tend to fit quite nicely. The only way you
can go wrong is by not trying.

Chapter 5 - When To Use MongoDB
-------------------------------

By now you should have a good enough understanding of MongoDB to have a
feel for where and how it might fit into your existing system. There are
enough new and competing storage technologies that it's easy to get
overwhelmed by all of the choices.

For me, the most important lesson, which has nothing to do with MongoDB,
is that you no longer have to rely on a single solution for dealing with
your data. No doubt, a single solution has obvious advantages and for a
lot projects, possibly even most, a single solution is the sensible
approach. The idea isn't that you must use different technologies, but
rather that you can. Only you know whether the benefits of introducing a
new solution outweigh the costs.

With that said, I'm hopeful that what you've seen so far has made you
see MongoDB as a general solution. It's been mentioned a couple times
that document-oriented databases share a lot in common with relational
databases. Therefore, rather than tiptoeing around it, let's simply
state that MongoDB should be seen as a direct alternative to relational
databases. Where one might see Lucene as enhancing a relational database
with full text indexing, or Redis as a persistent key-value store,
MongoDB is a central repository for your data.

Notice that I didn't call MongoDB a *replacement* for relational
databases, but rather an *alternative*. It's a tool that can do what a
lot of other tools can do. Some of it MongoDB does better, some of it
MongoDB does worse. Let's dissect things a little further.

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

In This Chapter
~~~~~~~~~~~~~~~

The message from this chapter is that MongoDB, in most cases, can
replace a relational database. It's much simpler and straightforward;
it's faster and generally imposes fewer restrictions on application
developers. The lack of transactions can be a legitimate and serious
concern. However, when people ask *where does MongoDB sit with respect
to the new data storage landscape?* the answer is simple: **right in the
middle**.

Chapter 6 - MapReduce
---------------------

MapReduce is an approach to data processing which has two significant
benefits over more traditional solutions. The first, and main, reason it
was development is performance. In theory, MapReduce can be
parallelized, allowing very large sets of data to be processed across
many cores/CPUs/machines. As we just mentioned, this isn't something
MongoDB is currently able to take advantage of. The second benefit of
MapReduce is that you get to write real code to do your processing.
Compared to what you'd be able to do with SQL, MapReduce code is
infinitely richer and lets you push the envelope further before you need
to use a more specialized solution.

MapReduce is a pattern that has grown in popularity, and you can make
use of it almost anywhere; C#, Ruby, Java, Python and so on all have
implementations. I want to warn you that at first this'll seem very
different and complicated. Don't get frustrated, take your time and play
with it yourself. This is worth understanding whether you are using
MongoDB or not.

A Mix of Theory and Practice
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MapReduce is a two-step process. First you map and then you reduce. The
mapping step transforms the inputted documents and emits a key=>value
pair (the key and/or value can be complex). The reduce gets a key and
the array of values emitted for that key and produces the final result.
We'll look at each step, and the output of each step.

The example that we'll be using is to generate a report of the number of
hits, per day, we get on a resource (say a webpage). This is the *hello
world* of MapReduce. For our purposes, we'll rely on a ``hits``
collection with two fields: ``resource`` and ``date``. Our desired
output is a breakdown by ``resource``, ``year``, ``month``, ``day`` and
``count``.

Given the following data in ``hits``:

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

We'd expect the following output:

::

    resource  year   month   day   count
    index     2010   1       20    3
    about     2010   1       20    1
    about     2010   1       21    3
    index     2010   1       21    2
    index     2010   1       22    1

(The nice thing about this type of approach to analytics is that by
storing the output, reports are fast to generate and data growth is
controlled (per resource that we track, we'll add at most 1 document per
day.)

For the time being, focus on understanding the concept. At the end of
this chapter, sample data and code will be given for you to try on your
own.

The first thing to do is look at the map function. The goal of map is to
make it emit a value which can be reduced. It's possible for map to emit
0 or more times. In our case, it'll always emit once (which is common).
Imagine map as looping through each document in hits. For each document
we want to emit a key with resource, year, month and day, and a simple
value of 1:

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

``this`` refers to the current document being inspected. Hopefully
what'll help make this clear for you is to see what the output of the
mapping step is. Using our above data, the complete output would be:

::

    {resource: 'index', year: 2010, month: 0, day: 20} => [{count: 1}, {count: 1}, {count:1}]
    {resource: 'about', year: 2010, month: 0, day: 20} => [{count: 1}]
    {resource: 'about', year: 2010, month: 0, day: 21} => [{count: 1}, {count: 1}, {count:1}]
    {resource: 'index', year: 2010, month: 0, day: 21} => [{count: 1}, {count: 1}]
    {resource: 'index', year: 2010, month: 0, day: 22} => [{count: 1}]

Understanding this intermediary step is the key to understanding
MapReduce. The values from emit are grouped together, as arrays, by key.
.NET and Java developers can think of it as being of type
``IDictionary<object, IList<object>>`` (.NET) or
``HashMap<Object, ArrayList>`` (Java).

Let's change our map function in some contrived way:

::

    function() {
        var key = {resource: this.resource, year: this.date.getFullYear(), month: this.date.getMonth(), day: this.date.getDate()};
        if (this.resource == 'index' && this.date.getHours() == 4) {
            emit(key, {count: 5});
        } else {
            emit(key, {count: 1}); 
        }
    }

The first intermediary output would change to:

::

    {resource: 'index', year: 2010, month: 0, day: 20} => [{count: 5}, {count: 1}, {count:1}]

Notice how each emit generates a new value which is grouped by our key.

The reduce function takes each of these intermediary results and outputs
a final result. Here's what ours looks like:

::

    function(key, values) {
        var sum = 0;
        values.forEach(function(value) {
            sum += value['count'];
        });
        return {count: sum};
    };

Which would output:

::

    {resource: 'index', year: 2010, month: 0, day: 20} => {count: 3}
    {resource: 'about', year: 2010, month: 0, day: 20} => {count: 1}
    {resource: 'about', year: 2010, month: 0, day: 21} => {count: 3}
    {resource: 'index', year: 2010, month: 0, day: 21} => {count: 2}
    {resource: 'index', year: 2010, month: 0, day: 22} => {count: 1}

Technically, the output in MongoDB is:

::

    _id: {resource: 'home', year: 2010, month: 0, day: 20}, value: {count: 3}

Hopefully you've noticed that this is the final result we were after.

If you've really been paying attention, you might be asking yourself
*why didn't we simply use ``sum = values.length``?* This would seem like
an efficient approach when you are essentially summing an array of 1s.
The fact is that reduce isn't always called with a full and perfect set
of intermediate data. For example, instead of being called with:

::

    {resource: 'home', year: 2010, month: 0, day: 20} => [{count: 1}, {count: 1}, {count:1}]

Reduce could be called with:

::

    {resource: 'home', year: 2010, month: 0, day: 20} => [{count: 1}, {count: 1}]
    {resource: 'home', year: 2010, month: 0, day: 20} => [{count: 2}, {count: 1}]

The final output is the same (3), the path taken is simply different. As
such, reduce must always be idempotent. That is, calling reduce multiple
times should generate the same result as calling it once.

We aren't going to cover it here but it's common to chain reduce methods
when performing more complex analysis.

Pure Practical
~~~~~~~~~~~~~~

With MongoDB we use the ``mapReduce`` command on a collection.
``mapReduce`` takes a map function, a reduce function and an output
directive. In our shell we can create and pass a JavaScript function.
From most libraries you supply a string of your functions (which is a
bit ugly). First though, let's create our simple data set:

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

Now we can create our map and reduce functions (the MongoDB shell
accepts multi-line statements, you'll see *...* after hitting enter to
indicate more text is expected):

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

Which we can use the ``mapReduce`` command against our ``hits``
collection by doing:

::

    db.hits.mapReduce(map, reduce, {out: {inline:1}})

If you run the above, you should see the desired output. Setting ``out``
to ``inline`` means that the output from ``mapReduce`` is immediately
streamed back to us. This is currently limited for results that are 16
megabytes or less. We could instead specify ``{out: 'hit_stats'}`` and
have the results stored in the ``hit_stats`` collections:

::

    db.hits.mapReduce(map, reduce, {out: 'hit_stats'});
    db.hit_stats.find();

When you do this, any existing data in ``hit_stats`` is lost. If we did
``{out: {merge: 'hit_stats'}}`` existing keys would be replaced with the
new values and new keys would be inserted as new documents. Finally, we
can ``out`` using a ``reduce`` function to handle more advanced cases
(such an doing an upsert).

The third parameter takes additional options, for example we could
filter, sort and limit the documents that we want analyzed. We can also
supply a ``finalize`` method to be applied to the results after the
``reduce`` step.

In This Chapter
~~~~~~~~~~~~~~~

This is the first chapter where we covered something truly different. If
it made you uncomfortable, remember that you can always use MongoDB's
other `aggregation
capabilities <http://www.mongodb.org/display/DOCS/Aggregation>`_ for
simpler scenarios. Ultimately though, MapReduce is one of MongoDB's most
compelling features. The key to really understanding how to write your
map and reduce functions is to visualize and understand the way your
intermediary data will look coming out of ``map`` and heading into
``reduce``.


