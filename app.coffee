express = require 'express'
http = require 'http'
instagram = require './instagram'
port = process.env.PORT || 5000
app = express()
server = app.listen port

console.log process.env

app.get '/', (req, res) ->
  req.socket.setTimeout Infinity
  res.writeHead 200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  }
  res.write 'hello\n'
  instagram.buildTagSubscription req.headers.host, 'test', (err, data) ->
      res.write(err+":"+data+'\n');
  
