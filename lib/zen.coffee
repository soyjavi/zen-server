###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/zen.server
###
"use strict"

formidable    = require "formidable"
fs            = require "fs"
Hope          = require "hope"
http          = require "http"
https         = require "https"
path          = require "path"
querystring   = require "querystring"
url           = require "url"

ZEN           = require "./zen.config"
CONST         = require "./zen.constants"
zenrequest    = require "./zen.request"
zenresponse   = require "./zen.response"
appnima       = require "./services/appnima"
mongo         = require "./services/mongo"
redis         = require "./services/redis"

module.exports =
  class ZenServer
    constructor: ->
      do @createEndpoints
      do @createServer

      Hope.shield([ =>
        do @services
      , =>
        do @statics
      , =>
        do @endpoints
      ]).then (error, value) =>
        process.exit() if error
        ZEN.br()
        console.log " Listening at :#{ZEN.port}", "(CTRL + C to shutdown)".grey
        ZEN.br()

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
            pattern   : new RegExp "^#{pattern}" # new RegExp '^' + pattern + '$'
            callback  : callback
            parameters: parameters

    createServer: ->
      @server = __server()
      @server.on "request", (request, response) =>
        response.request = url: request.url, method: request.method, at: new Date()
        response[method] = callback for method, callback of zenresponse
        response.setTimeout ZEN.timeout, -> response.requestTimeout()

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
          request.mobile = response.request.mobile = zenrequest.mobile request
          request.required = (values = []) -> zenrequest.required values, request, response

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
              request.parameters = __cast parameters
              endpoint.callback request, response
          else
            form = new formidable.IncomingForm
              multiples     : true
              keepExtensions: true
            form.parse request, (error, parameters, files) ->
              parameters = zenrequest.multipart error, parameters, files
              request.parameters = __cast parameters
              endpoint.callback request, response
        else
          response.page "404", undefined, undefined, 404

      @server.timeout = ZEN.timeout or CONST.TIMEOUT
      @server.listen ZEN.port
      do @handleErrors
      @server

    handleErrors: ->
      # @server.on "timeout", (response) -> response.end()
      @server.on "close", ->
        console.log ""
        ZEN.br "ZENserver shutdown..."
        if ZEN.mongo? then mongo.close()
        if ZEN.redis? then redis.close()
        console.log " ✓".green, "shutdown ok!".grey
        ZEN.br()
      process.on "uncaughtException", (error) =>
        console.log " ⚑  ERR".red, "uncaughtException:", error.message.grey
        process.exit 1
      process.on "SIGTERM", =>
        @server.close -> process.exit 1
      process.on "SIGINT", =>
        @server.close -> process.exit 1

    # -- Create endpoints ------------------------------------------------------
    endpoints: ->
      promise = new Hope.Promise()
      ZEN.br "ENDPOINTS"
      for context in ["api", "www"]
        for endpoint in ZEN[context] or []
          require("../../../#{context}/#{endpoint}") @
      promise.done undefined, true
      promise

    # -- Read static files -----------------------------------------------------
    statics: ->
      promise = new Hope.Promise()
      ZEN.br "STATICS"
      for policy in (ZEN.statics or []) when policy.url? or policy.file?
        do (policy) =>
          static_url = if policy.url? then "#{policy.url}" else "/#{policy.file}"
          @get static_url, (request, response) ->
            if policy.url
              file = url.parse(request.url).pathname.replace(policy.url, policy.folder)
            else
              file = "#{policy.folder}/#{policy.file}"
            file = "#{__dirname}/../../../#{file}"
            if fs.existsSync file
              last_modified = fs.statSync(file).mtime
              cache_modified = request.headers["if-modified-since"]
              if cache_modified? and __time(last_modified) is __time(cache_modified)
                mime_type = CONST.MIME[path.extname(file)?.slice(1)] or CONST.MIME.html
                response.run undefined, 304, mime_type
              else
                response.file file, policy.maxage, last_modified
            else
              response.page "404", undefined, undefined, 404
      promise.done undefined, true
      promise

    # -- Service Connections ---------------------------------------------------
    services: ->
      promise = new Hope.Promise()
      tasks = []
      if ZEN.mongo? or ZEN.redis? or ZEN.appnima
        ZEN.br "SERVICES"
        for connection in (ZEN.mongo or [])
          tasks.push do (connection) -> -> mongo.open connection
        if ZEN.redis?
          tasks.push => redis.open ZEN.redis
        if ZEN.appnima
          tasks.push => appnima.open ZEN.appnima

      if tasks.length > 0
        Hope.shield(tasks).then (error, value) =>
          process.exit() if error
          promise.done error, value
      else
        promise.done undefined, true
      promise

# -- Private methods -----------------------------------------------------------
__time = (value) -> (new Date(value)).getTime()

__server = ->
  if ZEN.protocol is "https"
    certificates = __dirname + "/../../../certificates/"
    https.createServer
      key   : fs.readFileSync("#{certificates}key.pem")
      cert  : fs.readFileSync("#{certificates}cert.pem")
  else
    http.createServer()

__cast = (values) ->
  for key, value of values when value in ["true", "false"]
    values[key] = JSON.parse value
  values
