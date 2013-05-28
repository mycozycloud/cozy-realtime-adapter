# Socket Listener

Helper library for interaction with cozy-data-system data changes notifications

##Server-Side : Redis -> Socket.io

Usage :

```coffee
module.exports = (compound) ->

    RealtimeAdapter = require 'cozy-realtime-adapter'

    customCb = (event, msg) ->
        # event = 'alarm.update' or 'alarm.create' or 'alarm.delete'
        # msg = id of the updated alarm

    # notification events should be proxyed to client
    realtime = RealtimeAdapter compound, ['notification.*']
    realtime.on 'alarm.*', customCb
```

if you don't use compound, simply pass a {server: httpServerObject} instead


##Client-Side : Socket.io -> Backbone Models manipulations

Basic Usage :

```html
<script src="cozy-realtime-adapter.js"></script>
```

```coffee
class SocketListener extends CozySocketListener

    models:
        'notification': Notification

    events: [
        'notification.create', 'notification.update', 'notification.delete'
    ]

    onRemoteCreate: (model) ->
        @collection.add model if # should model be in @collection ?

    onRemoteDelete: (model) ->
        @collection.remove model

sl = new SocketListener()

sl.watch myNotificationCollection
```

For more complex usages, refer to the code of cozy applications


# About Cozy

Cozy Realtime Adapter is a tools to ease development of Cozy Applications.
Cozy is the personal server for everyone. It allows you to install your every
day web applications easily on your server, a single place you control. This
means you can manage efficiently your data while protecting your privacy
without technical skills.

More informations and hosting services on:
https://cozycloud.cc

# Cozy on IRC

Feel free to check out our IRC channel (#cozycloud on irc.freenode.org) if you have any technical issues/inquiries or simply to speak about Cozy cloud in general.
