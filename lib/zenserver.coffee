"use strict"

# Libraries
http          = require "http"
https         = require "https"
url           = require "url"
querystring  = require "querystring"

ZenServer =

  run: ->
    console.log "ZENServer"

    http.createServer((request, response) ->

      unless request.url is "/favicon.ico"

        console.log "\nMETHOD   : #{request.method}"
        console.log "URL      : #{request.url}"
        console.log "PATHNAME : #{url.parse(request.url).pathname}"
        for key in url.parse(request.url).pathname.split("/").slice(1)
          console.log " -", key

        console.log "QUERY    : #{url.parse(request.url).query}"
        for key, value of url.parse(request.url, true).query
          console.log " -", key, value

        console.log "QUERYSTRING:"
        for key, value of querystring.parse(request.url)
          console.log key, value

      response.writeHead 200, "Content-Type": "text/plain"
      response.write "ZENserver"
      response.end()
    ).listen 8888

module.exports = ZenServer
