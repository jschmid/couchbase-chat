# Couchbase chat

A test app trying the capabilities of [Couchbase Server](http://www.couchbase.com/nosql-databases/couchbase-server), the [Sync Gateway](http://developer.couchbase.com/mobile/get-started/what-is-sync-gateway/index.html) and [Couchbase Lite](http://developer.couchbase.com/mobile/get-started/couchbase-lite-overview/index.html).

The app is a simple chat app with different chatrooms. A user can create a room and choose which user is included. Using roles and channels, each user receives only what he needs.

## Data model

Each couchbase document has a `type` property defining its model.

Default values are available in [data.json](sync-gateway/data.json).

### user

A user in the system. This allows users to select who has access to chat rooms.

Currently, the *user* documents have to be manually created using the same username as with the Sync Gateway users.

#### Properties

* username

### chatroom

A chatroom.

#### Properties

* name
* members: array of usernames that have access to the room

### message

A message in a chatroom

#### Properties

* room: the room id (not the name)
* created_at: date
* user: username
* message: text message

## Sync gateway config

The sync gateway [config.json](sync-gateway.json) file describes the config used for the app.

All users are in the `users` channel so that they all know about the other users when creating a new chat room.

When a user creates a new chat room, he selects the users he wants in the room. The sync function puts the `chatroom` and `message` documents in the same channel. Only the users selected when creating the room are added to the channel.
