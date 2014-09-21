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

  init: (data) ->
    promise = new Hope.Promise()
    if data.key? then @key = data.key
    if data.host? then @host = data.host
    console.log " ✓".green, "Appnima", "listening at".grey, "#{@host}".underline.blue
    promise.done null, true
    promise

  subscribe: (mail, callback) ->
    @_proxy "POST", "user/subscription", {mail: mail}, {Authorization: "basic #{@key}"}, callback

  signup: (user_agent, mail, password, username, name) ->
    promise = new Hope.Promise()
    @headers = Authorization: "basic #{@key}"
    @headers["user-agent"] = user_agent if user_agent
    parameters =
      mail      : mail
      password  : password
      username  : username
      name      : name
    @_proxy("POST", "user/signup", parameters, @headers).then (error, signup) ->
      promise.done error, signup
    promise


  login: (user_agent, mail, password, username, callback) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = user_agent if user_agent
    parameters =
      mail      : mail
      password  : password
      username  : username
    @_proxy "POST", "user/login", parameters, headers, callback


  refreshToken: (user_agent, refresh_token, callback) ->
    headers = Authorization: "basic #{@key}"
    headers["user-agent"] = user_agent if user_agent
    parameters =
      refresh_token : refresh_token
      grant_type    : "refresh_token"
    @_proxy "POST", "user/token", parameters, headers, callback


  api: (user_agent, method, url, token, parameters, callback) ->
    headers = {}
    headers["user-agent"] = user_agent if user_agent
    if token?
      headers.authorization = "bearer #{token}"
    @_proxy method, url, parameters, headers, callback

  _proxy: (method, url, parameters = {}, headers = {}, callback) ->
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
      result = JSON.parse body if body?
      if response.statusCode >= 400
        error = code: response.statusCode, message: result.message
        result = null
      promise.done error, result
      callback.call callback, error, result if callback?
    promise

module.exports = Appnima
