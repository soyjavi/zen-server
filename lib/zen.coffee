###
YOI
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/zen.server
###
"use strict"

http          = require "http"
https         = require "https"
url           = require "url"
querystring   = require "querystring"

page          = require "./zen.page"

module.exports =

  class ZenServer

    @HTTP_METHODS = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
    @URL_MATCH    =
      name  : /:([\w\d]+)/g
      splat : /\*([\w\d]+)/g
      escape: /[-[\]{}()+?.,\\^$|#\s]/g


    constructor: (@port = 80, @timeout = 1000) ->
      do @createEndpoints
      do @createServer
      console.log "ZENServer (#{@port}): CTRL + C to shutdown"


    createEndpoints: ->
      @methods = {}
      @methods[method] = [] for method in @constructor.HTTP_METHODS

      @constructor.HTTP_METHODS.forEach (method) =>
        @[method.toLowerCase()] = (pattern, callback) ->

          parameters = []
          for name, regexp of @constructor.URL_MATCH
            parameters.push(match[1]) while (match = regexp.exec(pattern)) isnt null

          pattern = pattern
            .replace(@constructor.URL_MATCH.escape, '\\$&')
            .replace(@constructor.URL_MATCH.name, '([^\/]*)')
            .replace(@constructor.URL_MATCH.splat, '(.*?)')

          @methods[method].push
            pattern   : new RegExp '^' + pattern + '$'
            callback  : callback
            parameters: parameters


    createServer: ->
      @instance = http.createServer (request, response, next) =>
        body = ""
        parameters = {}

        match = undefined
        for endpoint in @methods[request.method]
          match = endpoint.pattern.exec url.parse(request.url).pathname
          if match
            parameters[endpoint.parameters[i]] = value for value, i in match.slice(1)
            break

        if match
          console.log "< [#{request.method}] #{request.url}"

          request.on "data", (chunk) -> body += chunk.toString()

          request.on "end", ->
            if body isnt ""
              parameters[key] = value for key, value of querystring.parse body

            request.parameters = parameters
            request.required = (values = []) ->
              success = true
              for name in values when not @parameters[name]?
                success = false
                response.json message: "#{name} is required", 400
                break
              success

            response.json = (value, code, headers) ->
              run @, JSON.stringify(value), code, "application/json", headers

            response.html = (value, code, headers) ->
              run @, value.toString(), code, "text/html", headers

            response.page = page

            endpoint.callback request, response, next

          parameters[key] = value for key, value of url.parse(request.url, true).query

        else
          response.writeHead 200, "Content-Type": "text/play"
          response.write "Unknown"
          response.end()

      @instance.on 'error', (err) ->
        console.log 'there was an error:', err.message
      @instance.setTimeout @timeout, (callback) -> @ if @timeout
      @instance.listen @port
      @instance

    run = (response, value, code = 200, type = "application/json", headers = {}) ->
      console.log "> [#{response.statusCode}] #{value.length}"
      response.setHeader name, headers[name] for name of headers
      response.writeHead code, "Content-Type": type
      response.write value
      response.end()
