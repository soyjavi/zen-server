###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/services/appnima
###
"use strict"

request = require "request"
qs      = require "querystring"
Hope    = require "hope"

Appnima =

  host    : "http://api.appnima.com/"
  key     : ""

  open: (connection) ->
    promise = new Hope.Promise()
    if connection.key? then @key = connection.key
    if connection.host? then @host = connection.host
    console.log " ✓".green, "Appnima", "listening at".grey, "#{@host}".underline.blue
    promise.done null, true
    promise

  signup: (agent, mail, password, username, name) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = agent if agent
    parameters =
      mail      : mail
      password  : password
      username  : username
      name      : name
    @_proxy "POST", "user/signup", parameters, headers


  login: (agent, mail, password, username) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = agent if agent
    parameters =
      mail      : mail
      password  : password
      username  : username
    @_proxy "POST", "user/login", parameters, headers


  refreshToken: (agent, refresh_token) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = agent if agent
    parameters =
      refresh_token : refresh_token
      grant_type    : "refresh_token"
    @_proxy "POST", "user/token", parameters, headers


  api: (agent, method, url, token, parameters) ->
    headers = {}
    headers["user-agent"] = agent if agent
    headers.authorization = "bearer #{token}" if token?
    @_proxy method, url, parameters, headers

  _proxy: (method, url, parameters = {}, headers = {}) ->
    promise = new Hope.Promise()
    method = method.toUpperCase()
    options =
      method  : method
      uri     : "#{@host}#{url}"
      headers : headers
    if parameters? and (method is "GET" or method is "DELETE")
      options.uri += "?#{qs.stringify(parameters)}"
    else
      options.form = parameters
    request options, (error, response, body) ->
      value = JSON.parse body if body?
      if response.statusCode >= 400
        error = code: response.statusCode, message: value.message
        value = null
      promise.done error, value
    promise

module.exports = Appnima
