# create a bridge beween redis and socket.io for patterns
# compound : the compound object, or a server: httpServer Object
# patterns : the patterns to subscribe

# return an object with method
# on(pattern, callback(event, id)) to register custom callbacks

module.exports = (compound, patterns) ->

    sio = require 'socket.io'
    compound.io = sio.listen compound.server

    compound.io.set 'log level', 2
    compound.io.set 'transports', ['websocket']

    redis = require 'redis'
    client = redis.createClient()
    console.log ' socket.io initialized !'

    callbacks = {}

    defaultCallback = (ch, msg) ->
        compound.io.sockets.emit ch, msg

    registerCallback = (pattern, callback) ->
        cbs = callbacks[pattern]
        if not cbs?
            cbs = []
            client.psubscribe pattern
        cbs.push callback
        callbacks[pattern] = cbs

    client.on 'pmessage', (pattern, ch, msg) ->
        console.log pattern, ch, msg
        cbs = callbacks[pattern]
        callback ch, msg for callback in cbs

    # register default patterns
    for pattern in patterns
        registerCallback pattern, defaultCallback

    return on: registerCallback