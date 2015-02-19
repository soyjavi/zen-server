"use strict"

path          = require "path"
ZEN           = require "../zen.config"
CONST         = require "../zen.constants"

module.exports = (request, response, next) ->
  request[key] = method request for key, method of middleware
  request.required = (values = []) -> _required values, request, response
  request.multipart = _multipart

# -- Middleware ----------------------------------------------------------------
middleware =
  session: (request)->
    session = undefined
    key = global.ZEN.session?.authorization
    session = request.headers[key] if key? and request.headers[key]?
    request.headers.cookie?.split(";").forEach (cookie) ->
      parts = cookie.split("=")
      key = parts[0].trim()
      session = (parts[1] or "").trim() if key is global.ZEN.session?.cookie
    session

  mobile: (request) ->
    useragent = request.headers["user-agent"]?.toLowerCase()
    is_mobile = false
    if useragent?
      for type, regexp of CONST.MOBILE_AGENTS when regexp.test(useragent) is true
        is_mobile = true
        break
    is_mobile

  agent: (request) ->
    request.headers["user-agent"]?.toLowerCase()

  ip: (request) ->
    (
      request.headers["x-forwarded-for"]?.split(",")[0] or
      request.connection.remoteAddress or
      request.socket.remoteAddress or
      request.connection.socket?.remoteAddress)

# -- Private methods -----------------------------------------------------------
_multipart = (error, parameters, files) ->
    for field, values of files
      if Array.isArray(values)
        parameters[field] = (_file(value) for value in values when value.size > 0)
      else if values.size > 0
        parameters[field] = _file(values)
    parameters

_required = (values, request, response) ->
    success = true
    for name in values when not request.parameters[name]?
      success = false
      response.json message: "#{name} is required", 400
      break
    success

_file = (data) ->
  name: data.name
  type: data.type
  path: data.path
  size: data.size
