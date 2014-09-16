"use strict"

fs       = require "fs"
mustache = require "mustache"
path     = require "path"
zlib     = require "zlib"

CONST    = require "./zen.constants"

response =
  # -- Context variables -------------------------------------------------------
  mustaches: {}

  # -- Common responses ---------------------------------------------------------
  run: (body, code = 200, type = "application/json", headers = {}) ->
    headers["Content-Length"] = body.length
    @setHeader key, value for key, value of headers
    @writeHead code, "Content-Type": type
    @write body
    @end()
    console.log "> [#{@statusCode}] #{body.length}"

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
    for key, value of global.ZEN.headers when not headers[key]
      headers[key] =  if Array.isArray(value) then value.join(",") else value
    @run JSON.stringify(body), code, "application/json", headers

  successful: ->
    @json message: "successful", 200

  # -- STATIC files ------------------------------------------------------------
  file: (url, maxage = 60) ->
    if fs.existsSync(url) is true
      mime_type = CONST.MIME[path.extname(url)?.slice(1)] or CONST.MIME.html
      headers =
        "Content-Type"  : mime_type
        "Content-Length": fs.statSync(url).size
        "Cache-Control" : "max-age=#{maxage.toString()}"
      if mime_type.match(/#audio|video/)?
        @writeHead 200, headers
        readableStream = fs.createReadStream url
        readableStream.pipe @
      else
        @run fs.readFileSync(url) , 200, mime_type, headers
    else
      @page "404"

module.exports = response

__mustache = (name) ->
  dir = "#{__dirname}/../../../www/mustache/"
  if response.mustaches[name]
    response.mustaches[name]
  else if fs.existsSync file = "#{dir}#{name}.mustache"
    response.mustaches[name] = fs.readFileSync file, "utf8"
  else if fs.existsSync file = "#{dir}404.mustache"
    response.mustaches[name] = fs.readFileSync file, "utf8"
  else
    response.mustaches[name] = "<h1> 404 - Not found</h1>"
