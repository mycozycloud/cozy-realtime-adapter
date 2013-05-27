# create a bridge beween redis and socket.io for patterns
# compound : the compound object, or a server: httpServer Object
# patterns : the patterns to subscribe

# return an object with method
# on(pattern, callback(event, id)) to register custom callbacks

module.exports = (compound, patterns) ->

    path = require 'path'
    fs = require 'fs'
    sio = require 'socket.io'
    compound.io = sio.listen compound.server

    compound.io.set 'log level', 2
    compound.io.set 'transports', ['websocket']

    redis = require 'redis'
    client = redis.createClient()
    console.log ' socket.io initialized !'


    # serve lib/client.js under the url cozy-realtime-adapter.js
    oldListeners = compound.server.listeners('request').splice(0)
    compound.server.removeAllListeners 'request'
    compound.server.on 'request', (req, res) ->
        console.log req.url
        if req.url is '/cozy-realtime-adapter.js'
            filepath = path.resolve __dirname, '../lib/client.js'
            res.writeHead 200, 'Content-Type': 'text/javascript'
            fs.createReadStream(filepath).pipe res
        else
            for listener in oldListeners
                listener.call compound.server, req, res


    # the callbacks
    callbacks = {}

    # the default callback simply proxy the event through socket.io
    defaultCallback = (ch, msg) ->
        compound.io.sockets.emit ch, msg

    # add a callback
    registerCallback = (pattern, callback) ->
        cbs = callbacks[pattern]
        if not cbs?
            cbs = []
            client.psubscribe pattern
        cbs.push callback
        callbacks[pattern] = cbs

    # apply appropriate callbacks for each event
    client.on 'pmessage', (pattern, ch, msg) ->
        console.log pattern, ch, msg
        cbs = callbacks[pattern]
        callback ch, msg for callback in cbs


    # register default patterns
    patterns ?= []
    for pattern in patterns
        registerCallback pattern, defaultCallback

    return on: registerCallback