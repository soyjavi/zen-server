###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/zen.server
###
"use strict"

http          = require "http"
https         = require "https"
url           = require "url"
querystring   = require "querystring"


zenresponse   = require "./zen.response"
zenrequest    = require "./zen.request"

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

      for context in ["api", "www"]
        for endpoint in global.ZEN[context] or []
          require("../../../#{context}/#{endpoint}") @

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

        response[method] = callback for method, callback of zenresponse


        if match
          console.log "< [#{request.method}] #{request.url}"
          parameters[key] = value for key, value of url.parse(request.url, true).query

          request.on "data", (chunk) ->
            body += chunk.toString()
          request.on "end", ->
            if body isnt ""
              parameters[key] = value for key, value of querystring.parse body
            request.parameters = parameters

            request.session = zenrequest.session request
            request.required = (values = []) -> zenrequest.required values, request, response
            endpoint.callback request, response, next

        else
          response.page "404"

      do @handleErrors

      @instance.listen @port
      @instance

    handleErrors: ->
      @instance.on 'error', (err) ->
        console.log 'there was an error:', err.message
      @instance.on "uncaughtException", (request, response, error) ->
        response.send "error": error.message
        console.log error.message
        # shell "⚑", "red", "#{route.spec.method}", "/#{route.spec.path}", "ERROR: #{error.message}"
      @instance.setTimeout @timeout, (callback) -> @ if @timeout

      process.on "SIGTERM", =>
        @instance.close()
      process.on "SIGINT", =>
        @instance.close()
      process.on "exit", ->
        console.log "▣", "ZENserver", "stopped correctly"
      process.on "uncaughtException", (error) =>
        console.log "⚑", "red", "ZENserver", error.message
        process.exit()

    setCORS: ->

