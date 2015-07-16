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

The sync function is also included in the configuration file. Having Javascript code inside a JSON document make it very hard to read and text editors do not understand the syntax.

Creating the function on a JS file and pasting it into the configuration file is easier.

## Do not access Couchbase directly

Do every CRUD operation using the Sync Gateway API, never directly the Couchbase API. If you need special access to a bucket, check [bucket shadowing](https://github.com/couchbase/sync_gateway/wiki/Bucket-Shadowing).

## Website using Couchbase

The Sync Gateway is compatible with PouchDB, a Javascript database used on websites. Check [this article](http://blog.couchbase.com/first-steps-with-pouchdb--sync-gateway-todomvc-todolite) to learn about it.
