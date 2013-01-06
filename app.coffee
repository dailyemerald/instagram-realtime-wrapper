express = require 'express'
events = require 'events'
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
    true if req.query.token is (process.env.AUTH_TOKEN || 'test_token')
    false

publish = (message) ->
    message.time = new Date().toISOString()
    console.log message unless message.type is 'heartbeat'
    evt.emit 'publish', JSON.stringify message

app.get '/', (req, res) ->
    #unless verify_request_token(req)
    #    res.send(400, 'Need auth token.') 
    #    return

    req.socket.setTimeout Infinity
    res.writeHead 200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
    }
    evt.on 'publish', (message) ->
        res.write "data: #{message}\n\n"
    
app.get '/build/:tag', (req, res) ->
    instagram.buildTagSubscription req.headers.host, req.params.tag, (err, data) ->
        publish {'type': 'build_result', 'err': err, 'data': data}
    res.send ''
    
app.get '/notify/:name', (req, res) ->
    if req.query and req.query['hub.mode'] is 'subscribe'
        console.log "confirming new subscription for '#{req.params.name}' (query: #{JSON.stringify req.query})"
        res.send req.query['hub.challenge'] 
    else
        console.log "#{req.params.name}: #{req.body}"
        publish req.body

app.get '/list', (req, res) ->
    instagram.list_all (err, response, body) ->
        publish {'err': err, 'response': response, 'body': body}
        res.json [err, body]
    
app.post '/notify/:name', (req, res) ->
    res.send ''
    for notification in req.body
        evt.emit 'get_recent', notification

app.get '/delete_all', (req, res) ->
    res.send ''
    instagram.delete_all (error, data) ->
        publish {'error': error, 'data': data} 

evt.on 'get_recent', (notification) ->
    console.log "get_recent: #{notification}"
    url = instagram.get_recent_url_for(notification)
    #if url_err
    #    console.log "url_err: #{url_err}" 
    #    return

    request url, (err, response, body) ->    
        publish {'err': err, 'response': response, 'body': body}

 setInterval ->
    publish {'type': 'heartbeat'}
 , 1000*20    
