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
 As we just mentioned, this isn't something
MongoDB is currently able to take advantage of. The second benefit of
MapReduce is that you get to write real code to do your processing.
Compared to what you'd be able to do with SQL, MapReduce code is
infinitely richer and lets you push the envelope further before you need
to use a more specialized solution.

MapReduce 已經是愈來愈熱門的資料處理模式，\
你幾乎可以將它用在任何地方，像是 C#、Ruby、Java、Python 及其他的實作。\
我需要先告誡你的是，\
這種作法很不一樣也很複雜，\
先別沮喪，用點時間自己動手玩玩看，\
這相當值得用於瞭解你是否要使用 MongoDB。

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

重點回顧
=======

This is the first chapter where we covered something truly different. If
it made you uncomfortable, remember that you can always use MongoDB's
other `aggregation
capabilities <http://www.mongodb.org/display/DOCS/Aggregation>`_ for
simpler scenarios. Ultimately though, MapReduce is one of MongoDB's most
compelling features. The key to really understanding how to write your
map and reduce functions is to visualize and understand the way your
intermediary data will look coming out of ``map`` and heading into
``reduce``.


