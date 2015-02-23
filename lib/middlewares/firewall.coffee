"use strict"

path          = require "path"
ZEN           = require "../zen.config"

if ZEN.firewall?
  fs            = require "fs"
  path_firewall = "#{__dirname}/../../../../firewall"
  file_name     = "#{path_firewall}/blacklist.json"
  blacklist     = {}
  fs.mkdirSync path_firewall unless fs.existsSync path_firewall
  fs.readFile file_name, "utf8", (error, data) =>
    ZEN.blacklist = if error or data?.length is 0 then {} else JSON.parse data

module.exports =

  blacklist: (request, response, next) ->
    if parseInt(ZEN.blacklist?[request.ip]) >= (ZEN.firewall.ip or 10)
      response.writeHead 403
      response.end()

  extensions: (request, response, next) ->
    valid = true
    # -- Extensions control
    extension = path.extname(request.url)?.slice(1).toLowerCase()
    if extension in (ZEN.firewall.extensions or [])
      valid = false
      response.run "", code = 403

    # -- URL control
    if valid is true and request.url in (ZEN.firewall.urls or [])
      valid = false
      response.run "", code = 403

    # -- Add to blacklist
    if valid is false and request.ip not in ["127.0.0.1", "::1"]
      ZEN.blacklist[request.ip] = (ZEN.blacklist[request.ip] or 0) + 1
      # @TODO: Write async
      fs.writeFile file_name, JSON.stringify(ZEN.blacklist, null, 0), "utf8"
