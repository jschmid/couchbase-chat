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
* When the sync function validates a newly deleted document, it has to take care that all the properties have been removed. The function should treat deletions specially.

### Be extra careful when deleting a document that gives access to channels

Once a document is deleted, the access rights it has given to users/roles are revoked. If multiple documents give access to a channel, the rights are not revoked.

This means that when a document giving accesses is deleted, **no** document in the related channels will not be replicated to the users. This also means that the users will not be able to see that this particular document has been deleted (since they are not in the channel anymore).

There are multiple solutions to this:

* Put documents that give accesses and can be deleted in at least two channels. When the document is deleted it will stay in another channel which the users still have access and will see the deletion
* Create a "hardcoded" channel and give access to it to users using the sync gateway config file or the REST API. Doing this will prevent having channels that "disappear" when a document is deleted

See [this thread](https://groups.google.com/d/msg/mobile-couchbase/scBfRI7eeIA/JWd_K4QLyDUJ) and [this pull request](https://github.com/jschmid/couchbase-chat/pull/11) talking about a specific problem I had when developing the chat application.

### Validate everything on the client side

The sync function allows to put documents into channels, but it also acts as a security mechanism. Calls to `requireUser()`/`requireRole()`/`requireAccess()` are the only way to prevent users to do bad things on the server side.

However, this is only meant to prevent bad behavior from bad guys.
The client side must check everything on its side. In a perfect world, the sync function should never ever reject a document (apart from hacking attempts of course).

[This thread](https://groups.google.com/d/msg/mobile-couchbase/ijaSWNKWdww/hHIGLY1JKKMJ) shows a design decision made by the Couchbase folks. The client is not notified by the Couchbase Lite SDK when the sync gateway rejects a document. The client is therefore in a weird state where is has the document locally, already tried to sync it to the backend, but does not know that is has been rejected. The client will present the document to the user without knowing it is not and will never be synchronized.

When you put a document on your local database, it might be replicated hours after the user did the action. We cannot prompt the user to update he's document because he might not remember what he had done.

The client apps must be 100% sure that everything it creates will be validated by the sync gateway.

### The sync function must re-run entirely if it has changed

It seems normal that if it changes, the sync function will have to re-run on every document to find the newly added channels or roles.

[This thread](
https://forums.couchbase.com/t/sync-gateway-initial-shadow-scalability-concerns/3776) shows that this can cause problems with a production setup that already has thousands of documents. Currently, if the function changes, all Sync gateway instances must be brought down. Only one gateway can re-run on all documents. Only then the other instances can be brought up.

## Couchbase Lite does not have a "real" authentication mechanism

The documentation states that a user can authenticate using HTTP, Facebook, Persona, or a custom authentication.

The library code does not provide a way to check the credentials before going further in the app workflow.

For example, if you use the HTTP authentication:

* Configure the CBL replication object with the HTTP credentials
* Register to get notified when replication changes its status
* Start the replication
* Get notified that there is an error
  * Check the error and notice that this is an authentication error

The best way for me is the have the user authenticate to our own backend. Once the authentication succeeded, the backend sends a somewhat random username/password pair to the application which can use it to replicate with the Sync Gateway.

## Do not access Couchbase directly

Do every CRUD operation using the Sync Gateway API, never directly the Couchbase API. If you need special access to a bucket, check [bucket shadowing](https://github.com/couchbase/sync_gateway/wiki/Bucket-Shadowing), although it seems to have been [deprecated](https://gitter.im/couchbase/mobile?at=55a8d8c6ad99869443daa873).

## Website using Couchbase

The Sync Gateway is compatible with PouchDB, a Javascript database used on websites. Check [this article](http://blog.couchbase.com/first-steps-with-pouchdb--sync-gateway-todomvc-todolite) to learn about it.

## General thoughts

### NoSQL paradigm

Sometimes writing the sync function seems a bit cumbersome because we miss parameters, we cannot query the DB while in the sync function to get other info. We have to understand that sometimes data can and must be duplicated between multiple documents. Once this is understood, writing the sync function gets easier.
