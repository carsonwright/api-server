http = require('http')

http.createServer((req, res)->
    res.writeHead(200, {'Content-Type':'application/json'})
    res.end('{"error":"Unprocessable Entity"}')
).listen(1337, '127.0.0.1')
