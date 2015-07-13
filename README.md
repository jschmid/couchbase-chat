# Couchbase chat

A test app trying the capabilities of Couchbase, the Sync Gateway and Couchbase Lite.

The app is a simple chat app with different chatroom. A user can create a room and choose which use is included. Using roles and channels, each user receives only what he needs.

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
