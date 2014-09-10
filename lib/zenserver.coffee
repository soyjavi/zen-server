"use strict"

# Libraries
http          = require "http"
https         = require "https"
url           = require "url"
querystring   = require "querystring"

ZenServer =

  run: ->
    console.log "ZENServer: CTRL + C to shutdown"

    server = http.createServer((request, response) ->
      body = ""

      parameters = {}

      request.on "data", (chunk) -> body += chunk.toString()

      request.on "end", (message) ->
        if body isnt ""
          parameters[key] = value for key, value of querystring.parse body

        console.log " PARAMETERS :"
        for key, value of parameters
          console.log "  -", key, value
        response.end()

      unless request.url is "/favicon.ico"
        console.log "#{request.method} #{request.url}"
        console.log " NAMESPACES:"
        for key in url.parse(request.url).pathname.split("/").slice(1)
          console.log "  -", key
        parameters = url.parse(request.url, true).query

      response.writeHead 200, "Content-Type": "text/plain"
      response.write "ZENserver"
      # response.end()
    )

    server.setTimeout 1000, (callback) ->
      console.log ">"
    server.listen 8888

module.exports = ZenServer
