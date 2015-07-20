# Observations about Couchbase Lite

In this document I write everything I encountered by using Couchbase Lite and that we have to take care when developing an app with that.

## Mature project with some moving parts

With the 1.0 and 1.1 releases, the project is mature and ready for production. However, it also has some moving parts, like with the new ForestDB storage. Take care when making decisions about which parts of the technology to use.

## Replication works well

The library handles the synchronization and does it well. We don't have to worry about being disconnected. We work on the local database and the rest is handled transparently.

## Core Data wrapper

The distribution provides in its "Extras" folder, an implementation of `NSIncrementalStore` which allows to use Core Data to manipulate the documents instead of the regular CBL API: `CBLIncrementalStore`.

### All must be declared in Core Data for it to work

If you plan to use the Core Data wrapper for only a sub-part of the application, you still need to declare the whole data model (*.xcdatamodel*) for the wrapper to work.

In my tests, I wanted to use a NSFetchedResultsController to show items in a UITableView. I wanted to continue to use the regular CBL API for the other screens in the app. I still had to define every entity in the data model otherwise the wrapper would crash.

It also means we cannot have documents that do not have a specific "type" otherwise the store would not understand.

### Data must keep the "old" way of modeling data

Since Core Data is used like a regular ORM with SQL-like stores in mind, we lose the power of using denormalized documents. Each document must comply with the defined model.

A document can have more properties than those defined in the model, however it cannot have "child" documents.

### Can be used together with the regular CBL API

The regular CBL API is still available. This means we can use the wrapper for certain things, but keep CBL for others.

## The Sync Gateway configuration file

**Everything** related to the sync gateway is handled by one only file: server configuration, users, roles, authorization, channels. This way of doing is not really ideal since it might result in a huge bulky JSON file. Hopefully, it can be very easy to create one file per configuration type and merge them together to feed the `sync_gateway` command.

## The sync function

The sync function is also included in the configuration file. Having Javascript code inside a JSON document makes it very hard to read and text editors do not understand the syntax. Creating the function on a JS file and pasting it into the configuration file is easier.

The four main parts are users, roles, channels and of course documents.

* Users and roles are created in the configuration file or by the admin using the Admin REST API
* Users can have zero or multiple roles
* Roles are added to users by the admin or by the sync function
* Channels are created on the fly by the sync function
* There can be any number of channels
* Documents are assigned to channels by the sync function
* User and roles are given access to channels by the sync function
  * Once *one* document gives access to a channel, the user/role has access to every document in the channel
* The sync function is executed for each new revision of a document. The channels can therefore change for every new revision
* Once a document is deleted, the access rights it has given to users/roles are revoked. (See [this thread](https://groups.google.com/d/msg/mobile-couchbase/scBfRI7eeIA/JWd_K4QLyDUJ)). If multiple documents give access to a channel, the rights are not revoked.
* When the sync function validates a newly deleted document, it has to take care that all the properties have been removed. The function should treat deletions specially.

## Do not access Couchbase directly

Do every CRUD operation using the Sync Gateway API, never directly the Couchbase API. If you need special access to a bucket, check [bucket shadowing](https://github.com/couchbase/sync_gateway/wiki/Bucket-Shadowing), although it seems to have been [deprecated](https://gitter.im/couchbase/mobile?at=55a8d8c6ad99869443daa873).

## Website using Couchbase

The Sync Gateway is compatible with PouchDB, a Javascript database used on websites. Check [this article](http://blog.couchbase.com/first-steps-with-pouchdb--sync-gateway-todomvc-todolite) to learn about it.

## General thoughts

### NoSQL paradigm

Sometimes writing the sync function seems a bit cumbersome because we miss parameters, we cannot query the DB while in the sync function to get other info. We have to understand that sometimes data can and must be duplicated between multiple documents. Once this is understood, writing the sync function gets easier.
