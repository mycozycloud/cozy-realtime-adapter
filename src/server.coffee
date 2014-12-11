# create a bridge beween couchdb events and socket.io
# app : the express server object, or a server: httpServer Object
# patterns : the patterns to subscribe

# Return an object with method
# on(pattern, callback(event, id)) to register custom callbacks

path = require 'path'
fs = require 'fs'
sio = require 'socket.io'
axon = require 'axon'


module.exports = (app, patterns, options) ->

    unless process.env.NODE_ENV
        logging = console
    else
        logging = log: ->

    app.io = sio.listen app.server, options
    app.io.set 'log level', 2
    app.io.set 'transports', ['websocket']

    socket = axon.socket 'sub-emitter'
    socket.connect 9105

    logging.log 'Realtime-adapter : socket.io initialized !'

    # serve lib/client.js under the url cozy-realtime-adapter.js
    oldListeners = app.server.listeners('request').splice(0)
    app.server.removeAllListeners 'request'
    app.get '/cozy-realtime-adapter.js', (req, res) ->
        filepath = path.resolve __dirname, '../lib/client.js'
        res.writeHead 200, 'Content-Type': 'text/javascript'
        fs.createReadStream(filepath).pipe res


    # the default callback simply proxy the event through socket.io
    defaultCallback = (change, msg) ->
        app.io.sockets.emit change, msg

    # add a callback
    registerCallback = (pattern, callback) ->
        socket.on pattern, (event, id) ->
            if id
                event = pattern.replace '*', event # axon is too smart
                callback event, id
            else callback pattern, event


    # register default patterns
    patterns ?= []
    for pattern in patterns
        registerCallback pattern, defaultCallback

    return
        on: registerCallback
