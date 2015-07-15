# Data model

Each couchbase document has a `type` property defining its model name.

## user

A user in the system. This allows users to select who has access to chat rooms.

Currently, the *user* documents have to be manually created using the same username as with the Sync Gateway users.

### Properties

* username

## chatroom

A chatroom.

### Properties

* name
* user: the owner of the chat
* members: array of usernames that have access to the room

## message

A message in a chatroom

### Properties

* room: the room id (not the name)
* created_at: date
* user: username
* message: text message
