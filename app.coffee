http = require('http')
yaml = require('yamljs')
fs = require('fs')
pg = require('pg')
Object.prototype.reverse = ()->
  data = Object()
  for key in Object.keys(this)
    data[this[key]] = key
  data

files = fs.readdirSync("controllers")
fileContent = ""
for file in files
  fileContent += fs.readFileSync("controllers/#{file}", "utf8")
fileContent = yaml.parse(fileContent)
conString = "postgres://carson:mypasseasy@localhost/awesome"
http.createServer((req, res)->
  url = req.url.split("?")
  path = url[0]
  getParams = url[1]

  res.setHeader('Access-Control-Allow-Origin', 'http://localhost:8080');
  res.setHeader('Access-Control-Request-Method', '*');
  res.setHeader('Access-Control-Allow-Methods', 'OPTIONS, GET, POST, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Credentials', true);

  path = "#{req.method.toLowerCase()} #{path}"
  if fileContent[path]
    pg.connect(conString, (err, client, done)->
      if(err)
        return console.error('error fetching client from pool', err)
      
      processRequest = (data)->
        postSql = fileContent[path].sql
        params = fileContent[path].params
        if params
          for param in Object.keys(params)
            postSql = postSql.replace(new RegExp(param,"g"), data[params[param]]) 
        console.log(postSql)
        client.query(postSql, (err, result)->
          done()

          if(err)
            return console.error('error running query', err)
          
          res.writeHead(200, {'Content-Type':'application/json'})
          res.end(JSON.stringify(result.rows))

          client.end()
        )
      body = ""
      req.on('data', (data)->
          body += data
      )

      req.on('end', ()->
        body = body.split("&")
        data = Object()
        for line in body
          data[line.split("=")[0]] = line.split("=")[1]

        processRequest(data)
        body = ""
      )
    )
  else
    res.writeHead(404, {'Content-Type':'application/json'})
    res.end('{"error":"Unprocessable Entity"}')


).listen(1337, '127.0.0.1')
