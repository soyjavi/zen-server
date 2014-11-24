"use strict"

path          = require "path"

ZEN           = require "./zen.config"
CONST         = require "./zen.constants"
zenrequest    = require "./zen.request"
zenresponse   = require "./zen.response"

if ZEN.firewall?
  fs            = require "fs"
  path_firewall = "#{__dirname}/../../../firewall"
  file_name     = "#{path_firewall}/blacklist.json"
  blacklist     = {}
  fs.mkdirSync path_firewall unless fs.existsSync path_firewall
  fs.readFile file_name, "utf8", (error, data) =>
    ZEN.blacklist = if error or data?.length is 0 then {} else JSON.parse data

module.exports = (request, response) ->
  valid = true

  # Blacklist block
  if ZEN.firewall?
    request.ip = zenrequest.ip request
    if parseInt(ZEN.blacklist?[request.ip]) >= 10
      valid = false
      response.writeHead 403
      response.end()

  # Middleware
  response.request = url: request.url, method: request.method, at: new Date()
  response[method] = callback for method, callback of zenresponse
  response.setTimeout ZEN.timeout, -> response.requestTimeout()
  request.session = response.request.session  = zenrequest.session request
  request.agent = response.request.agent = zenrequest.agent request
  request.mobile = response.request.mobile = zenrequest.mobile request
  response.request.ip = request.ip

  if ZEN.firewall?
    # Extensions control
    extension = path.extname(request.url)?.slice(1).toLowerCase()
    if extension in (ZEN.firewall.extensions or [])
      valid = false
      response.run "", code = 403
      # Add to blacklist request
      ZEN.blacklist[request.ip] = (ZEN.blacklist[request.ip] or 0) + 1
      fs.writeFile file_name, JSON.stringify(ZEN.blacklist, null, 0), "utf8"

  # CORS Authorization
  if request.method.toUpperCase() is "OPTIONS"
    headers = {}
    for key, value of ZEN.headers
      headers[key] = if Array.isArray(value) then value.join(", ") else value
    headers = null if headers["Access-Control-Allow-Origin"] not in [request.headers.origin, "*"]
    response.writeHead "204", "No Content", headers
    response.end()
    valid = false

  valid
