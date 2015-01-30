"use strict"

ZEN           = require "../zen.config"

module.exports = (request, response, next) ->
  if request.method.toUpperCase() is "OPTIONS"
    headers = {}
    for key, value of ZEN.headers
      headers[key] = if Array.isArray(value) then value.join(", ") else value
    headers = null if headers["Access-Control-Allow-Origin"] not in [request.headers.origin, "*"]
    response.writeHead "204", "No Content", headers
    response.end()
