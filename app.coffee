express = require 'express'
events = require 'events'
request = require 'request'
http = require 'http'
instagram = require './instagram'
port = process.env.PORT || 5000
app = express()
server = app.listen port

app.configure ->
  app.use express.static(__dirname + "/public")
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.methodOverride()
  app.use express.errorHandler({showStack: true, dumpExceptions: true})

evt = new events.EventEmitter();

console.log "Started on port #{port}"

verify_request_token = (req) ->
    true if req.query.token is req.env.AUTH_TOKEN || 'test_token'
    false

#unless verify_request_token(req)
#        req.send(500, 'Need auth token.') 
#        return

app.get '/', (req, res) ->
    req.socket.setTimeout Infinity
    res.writeHead 200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
    }
    evt.on 'publish', (message) ->
        console.log message
        res.write "data: #{JSON.stringify message}\n\n"
    
app.get '/build/:tag', (req, res) ->
    instagram.buildTagSubscription req.headers.host, req.params.tag, (err, data) ->
        evt.emit 'publish', {'type': 'build_result', 'err': err, 'data': data}
    evt.emit 'publish', "/build/#{req.params.tag} called"
    res.send ''
    
app.get '/notify/:name', (req, res) ->
    
    evt.emit 'publish', {'type': 'info:notify', 'data': req.query}

    if req.query and req.query['hub.mode'] is 'subscribe'
        console.log "Confirming new Instagram real-time subscription for '#{req.params.name}' (query:#{req.query})"
        res.send req.query['hub.challenge'] 
    else
        console.log "#{req.params.name}: #{req.body}"
        evt.emit 'publish', req.body

app.get '/list', (req, res) ->
    request "https://api.instagram.com/v1/subscriptions?client_secret=#{process.env.CLIENT_SECRET}&client_id=#{process.env.CLIENT_ID}", (err, response, body) ->
        console.log err, body
        evt.emit 'publish', {'err': err, 'response': response, 'body': body}
    res.send ''

app.post '/notify/:name', (req, res) ->
    evt.emit 'publish', {'type': 'new_photo', 'name': req.params.name, 'data': req.body}
    res.send ''

 setInterval ->
    evt.emit 'publish', {'type': 'heartbeat'}
 , 1000*20    
