"use strict"

path          = require "path"

ZEN           = require "./zen.config"
CONST         = require "./zen.constants"
zenrequest    = require "./zen.request"
zenresponse   = require "./zen.response"

module.exports = (request, response) ->

  valid = true

  # Middleware
  response.request = url: request.url, method: request.method, at: new Date()
  response[method] = callback for method, callback of zenresponse
  response.setTimeout ZEN.timeout, -> response.requestTimeout()
  request.session = response.request.session  = zenrequest.session request
  request.agent = response.request.agent = zenrequest.agent request
  request.mobile = response.request.mobile = zenrequest.mobile request
  request.ip = response.request.ip = zenrequest.ip request

  if ZEN.firewall?
    # IP blacklist

    # Extensions control
    extension = path.extname(request.url)?.slice(1).toLowerCase()
    if extension in (ZEN.firewall.extensions or [])
      response.run "", code = 403
      valid = false

  # CORS Authorization
  if request.method.toUpperCase() is "OPTIONS"
    headers = {}
    for key, value of ZEN.headers
      headers[key] = if Array.isArray(value) then value.join(", ") else value
    headers["Access-Control-Allow-Origin"] = request.headers.origin or "*"
    response.writeHead "204", "No Content", headers
    response.end()
    valid = false

  valid
