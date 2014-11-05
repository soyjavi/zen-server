"use strict"

colors    = require "colors"
fs        = require "fs"
mustache  = require "mustache"
path      = require "path"
url       = require "url"
zlib      = require "zlib"

CONST     = require "./zen.constants"

if ZEN.monitor
  Monitor = require("./zen.monitor")
  monitor = new Monitor("request", ZEN.monitor.request)

response =

  # -- Session -----------------------------------------------------------------
  session: (value) ->
    @setHeader "Set-Cookie", __cookie value

  logout: ->
    @setHeader "Set-Cookie", __cookie null
    delete @request.session

  # -- Common responses ---------------------------------------------------------
  run: (body = "", code = 200, type = "application/json", headers = {}, audit = true) ->
    if not @headersSent
      length = if Buffer.isBuffer(body) then body.length else Buffer.byteLength body
      headers["Content-Length"] = length if body
      @setHeader key, value for key, value of headers
      @writeHead code, "Content-Type": type
      @write body
      @end()
      __output @request, @statusCode, type, body, audit

  redirect: (url) ->
    @writeHead 302, "Location": url
    @end()
    __output @request, 302

  # -- HTML responses ----------------------------------------------------------
  html: (value, body, headers = {}) ->
    @run value.toString(), body, "text/html", headers

  page: (file, bindings = {}, partials = [], code, headers = {}) ->
    files = {}
    files[partial] = __mustache partial for partial in partials or []
    bindings.zen = global.ZEN
    @html mustache.render(__mustache(file), bindings, files), code

  # -- JSON responses ----------------------------------------------------------
  json: (data = {}, code, headers = {}, audit = true) ->
    for key, value of global.ZEN.headers when not headers[key]
      headers[key] =  if Array.isArray(value) then value.join(",") else value
    @run JSON.stringify(data, null, 0), code, "application/json", headers, audit

  # -- STATIC files ------------------------------------------------------------
  file: (url, maxage = 60, last_modified = null) ->
    is_valid = false
    if fs.existsSync(url) and stat = fs.statSync(url)
      is_valid = true if stat?.isFile()

    if is_valid
      mime_type = CONST.MIME[path.extname(url)?.slice(1)] or CONST.MIME.html
      headers =
        "Content-Type"  : mime_type
        "Content-Length": stat.size
        "Cache-Control" : "max-age=#{maxage.toString()}"
        "Last-Modified" : last_modified
      if mime_type.match(/audio|video/)?
        @writeHead 200, headers
        readableStream = fs.createReadStream url
        readableStream.pipe @
        __output @request, 200, mime_type
      else
        fs.readFile url, (error, result) => @run result, 200, mime_type, headers
    else
      @page "404", undefined, undefined, 404

for code, status of CONST.STATUS
  do (status, code) -> response[status] = -> @json message: status, code

module.exports = response

# -- Private methods -----------------------------------------------------------
__cachedMustache = {}

__cookie = (value) ->
  key = global.ZEN.session.cookie
  if value?
    today = new Date()
    expires = new Date today.getTime() + (global.ZEN.session.expire * 1000)
  else
    expires = new Date(-1).toUTCString()
  cookie = "#{key}=#{value}; Expires=#{expires}"
  cookie += "; Path=#{global.ZEN.session.path or "/"}"
  cookie += "; Domain=#{global.ZEN.session.domain or ""}"
  cookie += "; HttpOnly=true"
  cookie += "; Secure=true" if ZEN.protocol is "https"
  cookie

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

__output = (request, code, type = "", body = "", audit = true) ->
  latence = new Date() - request.at
  color = "red"
  if (code >= 200 and code < 300)
    color = "green"
  else if (code >= 300 and code < 400)
    color = "blue"

  _in = "⇠"
  _out = "⇢"
  if request.session?
    _in = "⇤"
    _out = "⇥"

  console.log " #{_in} ".green, request.method.grey, url.parse(request.url).pathname,
    "#{_out}  #{code}"[color], "#{latence}ms", "#{type} #{body?.length}".grey

  if audit and ZEN.monitor
    monitor.append
      at    : request.at
      ip    : request.ip
      agent : request.agent
      method: request.method
      url   : url.parse(request.url).pathname
      code  : code
      type  : type
      ms    : latence
      size  : body?.length
