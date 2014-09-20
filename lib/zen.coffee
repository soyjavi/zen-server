###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/zen.server
###
"use strict"

formidable    = require "formidable"
Hope          = require "hope"
http          = require "http"
https         = require "https"
querystring   = require "querystring"
url           = require "url"

ZEN           = require "./zen.config"
CONST         = require "./zen.constants"
zenrequest    = require "./zen.request"
zenresponse   = require "./zen.response"

# appnima       = require "./services/appnima"
mongo         = require "./services/mongo"
redis         = require "./services/redis"

module.exports =

  class ZenServer

    constructor: ->
      do @createEndpoints
      do @createServer
      # -- Read resources ------------------------------------------------------
      global.ZEN.br()
      console.log " ▣ ENDPOINTS"
      for context in ["api", "www"]
        for endpoint in global.ZEN[context] or []
          require("../../../#{context}/#{endpoint}") @
      # -- Read static files ---------------------------------------------------
      global.ZEN.br()
      console.log " ▣ STATICS"
      for policy in global.ZEN.statics or []
        do (policy) =>
          @get policy.url + "/:resource", (request, response, next) ->
            folder = policy.folder
            folder += "/#{request.parameters.folder}" if request.parameters.folder
            file = request.parameters.resource
            response.file "#{__dirname}/../../../#{folder}/#{file}", policy.maxage
      # -- Service Connections -------------------------------------------------
      tasks = []
      for connection in (global.ZEN.mongo or [])
        tasks.push do (connection) -> -> mongo.open connection
      if global.ZEN.redis?
        tasks.push => redis.open global.ZEN.redis
      if tasks.length > 0
        Hope.shield(tasks).then (error, value) =>
          process.exit() if error
          global.ZEN.br()
          console.log " CTRL + C to shutdown".grey
          global.ZEN.br()

    createEndpoints: ->
      @methods = {}
      CONST.HTTP_METHODS.forEach (method) =>
        @methods[method] = []
        @[method.toLowerCase()] = (pattern, callback) ->
          console.log " ✓".green, "[#{method.substr(0,3)}]".grey, "#{pattern}"
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
        response.request = url: request.url, at : new Date()
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
          # Middleware
          request.session = response.request.session  = zenrequest.session request
          request.required = (values = []) -> zenrequest.required values, request, response
          arrow = if request.session then "⇤" else "⇠"
          console.log " #{arrow} ".green, request.method.grey, url.parse(request.url).pathname

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
              endpoint.callback request, response, next
          else
            form = new formidable.IncomingForm
              multiples     : true
              keepExtensions: true
            form.parse request, (error, parameters, files) ->
              request.parameters = zenrequest.multipart error, parameters, files
              endpoint.callback request, response, next
        else
          console.log " ⇠  #{request.method} #{request.url}".grey
          response.page "404", undefined, undefined, 404

      do @handleErrors
      @server.listen ZEN.port
      @server


    handleErrors: ->
      @server.on 'error', (err) ->
        console.log 'there was an error:', err.message
      @server.on "uncaughtException", (request, response, error) ->
        response.send "error": error.message
        console.log " ⚑".red, request.url, "ERROR: #{error.message}"
      @server.setTimeout ZEN.timeout, (callback) -> @ if ZEN.timeout

      process.on "SIGTERM", =>
        @server.close()
      process.on "SIGINT", =>
        @server.close()
      process.on "exit", =>
        console.log "\n ▣", "ZENserver", "stopped correctly"
      process.on "uncaughtException", (error) =>
        console.log " ⚑".red, "ZENserver", error.message
        process.exit()
