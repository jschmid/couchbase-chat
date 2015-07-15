# Couchbase chat

A test app trying the capabilities of [Couchbase Server](http://www.couchbase.com/nosql-databases/couchbase-server), the [Sync Gateway](http://developer.couchbase.com/mobile/get-started/what-is-sync-gateway/index.html) and [Couchbase Lite](http://developer.couchbase.com/mobile/get-started/couchbase-lite-overview/index.html).

The app is a simple chat app with different chatrooms. A user can create a room and choose which user is included. Using roles and channels, each user receives only what he needs.

## Sync gateway config

The sync gateway [config.json](sync-gateway.json) file describes the config used for the app.

All users are in the `users` channel so that they all know about the other users when creating a new chat room.

When a user creates a new chat room, he selects the users he wants in the room. The sync function puts the `chatroom` and `message` documents in the same channel. Only the users selected when creating the room are added to the channel.

Validation is used to prevent users to delete documents (chatrooms, messages) that they do not own. Only the *admin* user can create user documents.

## Default data

Default values are available in [data.json](sync-gateway/data.json).
The config does not allow guest access. In order to fill in default data, execute the `bootstrap_data.sh` file to create the data as the admin user.

## Data model

The data model is described in [data_model.md](sync-gateway/data_model.md).
