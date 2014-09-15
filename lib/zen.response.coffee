"use strict"

fs       = require "fs"
mustache = require "mustache"


module.exports =

  # -- Common responses ----------------------------------------------------------
  run: (body, code = 200, type = "application/json", headers = {}) ->
    headers["Content-Length"] = body.length
    @setHeader key, value for key, value of headers
    @writeHead code, "Content-Type": type
    @write body
    @end()
    console.log "> [#{@statusCode}] #{value.length}"

  redirect: (url) ->
    @writeHead 302, "Location": url
    @end()
    console.log ">> [#{@statusCode}] #{url}"

  # -- HTML responses ----------------------------------------------------------
  html: (value, code, headers = {}) ->
    @run value.toString(), code, "text/html", headers

  page: (file, data, partials = []) ->
    files = {}
    files[partial] = __mustache partial for partial in partials or []
    @html mustache.to_html __mustache(file), data, files

  # -- JSON responses ----------------------------------------------------------
  json: (body = {}, code, headers = {}) ->
    # CORS
    for key, value of global.ZEN.headers
      headers[key] =  if Array.isArray(value) then value.join(",") else value
    @run JSON.stringify(body), code, "application/json", headers

  successful: ->
    @json message: "successful", 200

__mustache = (file) ->
  dir = "#{__dirname}/../../../www/mustache/"
  try
    fs.readFileSync "#{dir}#{file}.mustache", "utf8"
  catch error
    try
      fs.readFileSync "#{dir}404.mustache", "utf8"
    catch error
      "<h1> 404 - Not found</h1>"
