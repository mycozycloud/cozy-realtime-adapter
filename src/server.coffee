# create a bridge beween redis and socket.io for patterns
# compound : the compound object, or a server: httpServer Object
# patterns : the patterns to subscribe

# return an object with method
# on(pattern, callback(event, id)) to register custom callbacks

module.exports = (compound, patterns, options) ->

    unless process.env.NODE_ENV
        logging = console
    else
        logging = log: ->


    path = require 'path'
    fs = require 'fs'
    sio = require 'socket.io'
    compound.io = sio.listen compound.server, options

    compound.io.set 'log level', 2
    compound.io.set 'transports', ['websocket']

    axon = require 'axon'
    socket = axon.socket 'sub-emitter'
    socket.connect 9105

    logging.log 'Realtime-adapter : socket.io initialized !'


    # serve lib/client.js under the url cozy-realtime-adapter.js
    oldListeners = compound.server.listeners('request').splice(0)
    compound.server.removeAllListeners 'request'
    compound.server.on 'request', (req, res) ->
        if req.url is '/cozy-realtime-adapter.js'
            filepath = path.resolve __dirname, '../lib/client.js'
            res.writeHead 200, 'Content-Type': 'text/javascript'
            fs.createReadStream(filepath).pipe res
        else
            for listener in oldListeners
                listener.call compound.server, req, res


    # the default callback simply proxy the event through socket.io
    defaultCallback = (ch, msg) ->
        compound.io.sockets.emit ch, msg

    # add a callback
    registerCallback = (pattern, callback) ->
        socket.on pattern, (event, id) ->
            if id
                event = pattern.replace '*', event #axon is too smart
                callback event, id
            else callback pattern, event


    # register default patterns
    patterns ?= []
    for pattern in patterns
        registerCallback pattern, defaultCallback

    return on: registerCallback