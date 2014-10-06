###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/services/appnima
###
"use strict"

http    = require "http"
qs      = require "querystring"
Hope    = require "hope"

Appnima =
  key     : ""
  protocol: "http"
  host    : "api.appnima.com"
  port    : 80

  open: (connection) ->
    promise = new Hope.Promise()
    for key in ["key", "protocol", "host", "port"] when connection[key]?
      @[key] = connection[key]
    console.log " ✓".green, "Appnima", "listening at".grey, "#{@host}".underline.blue
    promise.done null, true
    promise

  signup: (parameters, agent) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = agent if agent
    @_proxy "POST", "user/signup", parameters, headers

  login: (parameters, agent) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = agent if agent
    @_proxy "POST", "user/login", parameters, headers

  refreshToken: (agent, refresh_token) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = agent if agent
    parameters =
      refresh_token : refresh_token
      grant_type    : "refresh_token"
    @_proxy "POST", "user/token", parameters, headers

  api: (parameters, agent) ->
    headers = {}
    headers["user-agent"] = agent if agent
    headers.authorization = "bearer #{parameters.token}" if parameters.token?
    @_proxy parameters.method, parameters.url, parameters.values, headers

  _proxy: (method, url, parameters = {}, headers = {}) ->
    promise = new Hope.Promise()

    options =
      host    : @host
      port    : @port
      path    : "/#{url}"
      method  : method.toUpperCase()
      headers : headers
      agent   : false

    body = ""
    if parameters? and (options.method is "GET" or options.method is "DELETE")
      options.path += "?#{qs.stringify(parameters)}"
    else
      body = qs.stringify parameters
      options.headers["Content-Type"] = "application/x-www-form-urlencoded"
      options.headers["Content-Length"] = body.length

    client = http.request options, (response) =>
      body = ""
      response.setEncoding "utf8"
      response.on "data", (chunk) -> body += chunk
      response.on "end", ->
        body = JSON.parse body if body?
        if response.statusCode >= 400
          error = code: response.statusCode, message: body.message
          body = undefined
        promise.done error, body

    client.on "error", (error) ->
      error = code: error.statusCode, message: error.message
      promise.done error, undefined

    client.write body
    client.end()

    promise

module.exports = Appnima
