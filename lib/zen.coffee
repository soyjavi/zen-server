###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/zen.server
###
"use strict"

domain        = require "domain"
formidable    = require "formidable"
fs            = require "fs"
Hope          = require "hope"
http          = require "http"
https         = require "https"
os            = require "os"
path          = require "path"
querystring   = require "querystring"
url           = require "url"
ZEN           = require "./zen.config"
CONST         = require "./zen.constants"
# -- Services
appnima       = require "./services/appnima" if ZEN.appnima?
mongo         = require "./services/mongo" if ZEN.mongo?
redis         = require "./services/redis" if ZEN.redis?
# -- Middlewares
request       = require "./middlewares/request"
firewall      = require "./middlewares/firewall" if ZEN.firewall?
response      = require "./middlewares/response"
cors          = require "./middlewares/cors"

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
        __monitorProcess()
        process.exit() if error
        ZEN.br()
        console.log " Listening at :#{ZEN.port}", "(CTRL + C to shutdown)".grey
        ZEN.br()
        @

    use: (callback, system = false) =>
      @middleware = @middleware or []
      @middleware.push
        callback: callback
        system  : system

    createEndpoints: ->
      @use request, system = true
      @use response, system = true
      @use cors, system = true
      @use firewall.blacklist, system = true if ZEN.firewall?
      @use firewall.extensions, system = true if ZEN.firewall?

      @methods = {}
      CONST.HTTP_METHODS.forEach (method) =>
        @methods[method] = []
        @[method.toLowerCase()] = (pattern, callback, handler = true) ->
          console.log " ✓".green, "[#{method.substr(0,3)}]".grey, "#{pattern}"
          parameters = []
          for name, regexp of CONST.URL_MATCH
            parameters.push(match[1]) while (match = regexp.exec(pattern)) isnt null

          pattern = pattern
            .replace(CONST.URL_MATCH.escape, '\\$&')
            .replace(CONST.URL_MATCH.name, '([^\/]*)')
            .replace(CONST.URL_MATCH.splat, '(.*?)')
          pattern = if handler then "^#{pattern}$" else "^#{pattern}"

          @methods[method].push
            pattern   : new RegExp pattern
            callback  : callback
            parameters: parameters
            handler   : handler

    createServer: ->
      @server = __server()
      @server.on "request", (request, response, next) =>
        ZEN.domain = domain.create()
        ZEN.domain.add request
        ZEN.domain.add response
        ZEN.domain.on "error", (error) ->
          __errorStack error
          response.internalServerError()

        body = ""
        parameters = {}
        match = undefined
        request_method = @methods[request.headers["access-control-request-method"]]

        for key, value of request_method when request.method is "OPTIONS"
          @methods["OPTIONS"] = request_method if value.pattern.toString().match request.url

        for endpoint in @methods[request.method]
          match = endpoint.pattern.exec url.parse(request.url).pathname
          if match
            parameters[endpoint.parameters[i]] = value for value, i in match.slice(1)
            break

        for use in @middleware when not response.headersSent
          if endpoint.handler or use.system
            use.callback.apply @, [request, response, next]

        if match
          parameters[key] = value for key, value of url.parse(request.url, true).query
          unless request.headers["content-type"]?.match(CONST.REGEXP.MULTIPART)?
            request.on "data", (chunk) ->
              body += chunk.toString()
              if body.length > 1e6
                body = ""
                response.run "", 413, "text/plain"
                request.connection.destroy()
            request.on "end", =>
              if body isnt ""
                if request.headers["content-type"] is CONST.MIME.json
                  parameters[key] = value for key, value of JSON.parse body
                else
                  parameters[key] = value for key, value of querystring.parse body
              request.parameters = __cast parameters
              endpoint.callback.apply @, [request, response, next]
          else
            form = new formidable.IncomingForm
              multiples     : true
              keepExtensions: true
            form.parse request, (error, parameters, files) =>
              parameters = request.multipart error, parameters, files
              request.parameters = __cast parameters
              endpoint.callback.apply @, [request, response, next]
        else
          response.page "404", undefined, undefined, 404

      @server.timeout = ZEN.timeout or CONST.TIMEOUT
      @server.listen ZEN.port
      do @handleProcess
      @server

    handleProcess: ->
      process.on "uncaughtException", (error) =>
        __errorStack error
        process.exit 1
      for event in ["SIGTERM", "SIGINT"]
        process.on event, =>
          do __serverClose
          @server.close()
          process.exit 0

    # -- Create endpoints ------------------------------------------------------
    endpoints: ->
      promise = new Hope.Promise()
      ZEN.br "ENDPOINTS"
      do @monitor if ZEN.monitor
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
          , handler = false
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

    # -- Audit requests --------------------------------------------------------
    monitor: ->
      @get "/monitor/:password/:file/:date", (request, response) ->
        if request.parameters.password is ZEN.monitor.password
          file = "#{request.parameters.file}.#{request.parameters.date}.json"
          fs.readFile "#{__dirname}/../../../monitor/#{file}", (error, data) ->
            unless error
              response.json JSON.parse(data), 200, headers = {}, audit = false
            else
              response.notFound()
        else
          response.unauthorized()

# -- Private methods -----------------------------------------------------------
__time = (value) -> (new Date(value)).getTime()

__server = ->
  if ZEN.protocol is "https"
    certificates = __dirname + "/../../../certificates/"
    https.createServer
      cert  : fs.readFileSync("#{certificates}#{ZEN.cert}")
      key   : fs.readFileSync("#{certificates}#{ZEN.key}")
  else
    http.createServer()

__serverClose = ->
  console.log ""
  ZEN.br "ZENserver shutdown..."
  if ZEN.mongo? then mongo.close()
  if ZEN.redis? then redis.close()
  console.log " ✓".green, "shutdown ok!".grey
  ZEN.br()

__cast = (values) ->
  for key, value of values when value in ["true", "false"]
    values[key] = JSON.parse value
  values

__monitorProcess = ->
  if ZEN.monitor
    Monitor = require("./zen.monitor")
    monitor = new Monitor("server", ZEN.monitor.process)
    MB = 1024 * 1024
    setInterval =>
      monitor.append
        at      : new Date()
        pid     : process.pid
        uptime  : process.uptime()
        memtotal: process.memoryUsage().heapTotal / MB
        system  :
          uptime  : os.uptime()
          freemem : os.freemem()/ MB
          loadavg : os.loadavg()
    , ZEN.monitor.process

__errorStack = (error) ->
  console.log(" ⚑ [uncaughtException]".red, new Date().toString().grey,
    "\n   #{error.message}".red,
    "\n  ", error.stack)
  file_name = "#{__dirname}/../../../zen.error.json"
  error =
    date: new Date()
    stack: error.stack
  fs.writeFileSync file_name, JSON.stringify(error, null, 0), "utf8"
