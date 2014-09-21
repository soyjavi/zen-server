"use strict"

colors   = require "colors"
fs       = require "fs"
mustache = require "mustache"
path     = require "path"
url      = require "url"
zlib     = require "zlib"

CONST    = require "./zen.constants"

response =

  # -- Common responses ---------------------------------------------------------
  run: (body, code = 200, type = "application/json", headers = {}) ->
    headers["Content-Length"] = body?.length
    @setHeader key, value for key, value of headers
    @writeHead code, "Content-Type": type
    @write body
    @end()
    __output @request, @statusCode, type, body

  redirect: (url) ->
    @writeHead 302, "Location": url
    @end()
    __output @request, 302

  # -- HTML responses ----------------------------------------------------------
  html: (value, code, headers = {}) ->
    @run value.toString(), code, "text/html", headers

  page: (file, data, partials = [], code) ->
    files = {}
    files[partial] = __mustache partial for partial in partials or []
    @html mustache.to_html(__mustache(file), data, files), code

  # -- JSON responses ----------------------------------------------------------
  json: (body = {}, code, headers = {}) ->
    for key, value of global.ZEN.headers when not headers[key]
      headers[key] =  if Array.isArray(value) then value.join(",") else value
    @run JSON.stringify(body), code, "application/json", headers

  # -- STATIC files ------------------------------------------------------------
  file: (url, maxage = 60) ->
    if fs.existsSync(url) is true
      mime_type = CONST.MIME[path.extname(url)?.slice(1)] or CONST.MIME.html
      headers =
        "Content-Type"  : mime_type
        "Content-Length": fs.statSync(url).size
        "Cache-Control" : "max-age=#{maxage.toString()}"
      if mime_type.match(/audio|video/)?
        @writeHead 200, headers
        readableStream = fs.createReadStream url
        readableStream.pipe @
        __output @request, 200, mime_type
      else
        @run fs.readFileSync(url), 200, mime_type, headers
    else
      @page "404", undefined, undefined, 404

for code, status of CONST.STATUS
  do (status, code) -> response[status] = -> @json message: status, code

module.exports = response

__cachedMustache = {}

__mustache = (name) ->
  dir = "#{__dirname}/../../../www/mustache/"
  if __cachedMustache[name]
    __cachedMustache[name]
  else if fs.existsSync file = "#{dir}#{name}.mustache"
    __cachedMustache[name] = fs.readFileSync file, "utf8"
  else if fs.existsSync file = "#{dir}404.mustache"
    __cachedMustache[name] = fs.readFileSync file, "utf8"
  else
    __cachedMustache[name] = "<h1> 404 - Not found</h1>"

__output = (request, code, type = "", body = "") ->
  gap = new Date() - request.at
  color = "red"
  if (code >= 200 and code < 300)
    color = "green"
  else if (code >= 300 and code < 400)
    color = "blue"

  if request.session?
    _in = "⇤"
    _out = "⇥"
  else
    _in = "⇠"
    _out = "⇢"

  console.log " #{_in} ".green, request.method.grey, url.parse(request.url).pathname,
    "#{_out}  #{code}"[color], "#{gap}ms", "#{type} #{body?.length}".grey
