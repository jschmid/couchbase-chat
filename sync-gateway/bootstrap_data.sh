#!/bin/bash

if !(which http >/dev/null); then
    echo "Please install HTTPie"
    echo https://github.com/jkbrzt/httpie
    exit -1
fi

host=http://localhost:4984/couchbase-chat/

http --session=chat-admin "$host"_session name=admin password=admin

http --session=chat-admin POST "$host"_bulk_docs < data.json
