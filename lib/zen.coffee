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
formidable    = require "formidable"

CONST         = require "./zen.constants"
zenresponse   = require "./zen.response"
zenrequest    = require "./zen.request"

module.exports =

  class ZenServer

    constructor: (@port = 80, @timeout = 1000) ->
      do @createEndpoints
      do @createServer
      # -- Read resources ------------------------------------------------------
      for context in ["api", "www"]
        for endpoint in global.ZEN[context] or []
          require("../../../#{context}/#{endpoint}") @
      # -- Read static files ---------------------------------------------------
      for policy in global.ZEN.statics or []
        do (policy) =>
          @get policy.url + "/:resource", (request, response, next) ->
            folder = policy.folder
            folder += "/#{request.parameters.folder}" if request.parameters.folder
            file = request.parameters.resource
            response.file "#{__dirname}/../../../#{folder}/#{file}", policy.maxage

      console.log "ZENServer (#{@port}): CTRL + C to shutdown"

    createEndpoints: ->
      @methods = {}
      CONST.HTTP_METHODS.forEach (method) =>
        @methods[method] = []
        @[method.toLowerCase()] = (pattern, callback) ->
          parameters = []
          for name, regexp of CONST.URL_MATCH
            parameters.push(match[1]) while (match = regexp.exec(pattern)) isnt null

          pattern = pattern
            .replace(CONST.URL_MATCH.escape, '\\$&')
            .replace(CONST.URL_MATCH.name, '([^\/]*)')
            .replace(CONST.URL_MATCH.splat, '(.*?)')

          @methods[method].push
            pattern   : new RegExp '^' + pattern + '$'
            callback  : callback
            parameters: parameters

    createServer: ->
      @server = http.createServer (request, response, next) =>
        response[method] = callback for method, callback of zenresponse

        body = ""
        parameters = {}
        match = undefined
        for endpoint in @methods[request.method]
          match = endpoint.pattern.exec url.parse(request.url).pathname
          if match
            parameters[endpoint.parameters[i]] = value for value, i in match.slice(1)
            break

        if match
          parameters[key] = value for key, value of url.parse(request.url, true).query

          unless request.headers["content-type"]?.match(CONST.REGEXP.MULTIPART)?
            request.on "data", (chunk) ->
              body += chunk.toString()
              if body.length > 1e6
                  body = ""
                  response.run "", 413, "text/plain"
                  request.connection.destroy()

            request.on "end", ->
              if body isnt ""
                parameters[key] = value for key, value of querystring.parse body
              request.parameters = parameters
              request.session = zenrequest.session request
              request.required = (values = []) -> zenrequest.required values, request, response
              endpoint.callback request, response, next
          else
            form = new formidable.IncomingForm
              multiples     : true
              keepExtensions: true
            form.parse request, (error, parameters, files) ->
              request.parameters = zenrequest.multipart error, parameters, files
              endpoint.callback request, response, next
        else
          response.page "404"

      do @handleErrors
      @server.listen @port
      @server


    handleErrors: ->
      @server.on 'error', (err) ->
        console.log 'there was an error:', err.message
      @server.on "uncaughtException", (request, response, error) ->
        response.send "error": error.message
        console.log error.message
        # shell "⚑", "red", "#{route.spec.method}", "/#{route.spec.path}", "ERROR: #{error.message}"
      @server.setTimeout @timeout, (callback) -> @ if @timeout

      process.on "SIGTERM", =>
        @server.close()
      process.on "SIGINT", =>
        @server.close()
      process.on "exit", =>
        console.log "▣", "ZENserver", "stopped correctly"
      process.on "uncaughtException", (error) =>
        console.log "⚑", "red", "ZENserver", error.message
        process.exit()
