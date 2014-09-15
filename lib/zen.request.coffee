"use strict"

module.exports =

  session: (request)->
    session = undefined
    key = global.ZEN.session.authorization
    session = request.headers[key] if request.headers[key]?
    request.headers.cookie?.split(";").forEach (cookie) ->
      parts = cookie.split("=")
      key = parts[0].trim()
      session = (parts[1] or "" ).trim() if key is global.ZEN.session.cookie
    session

  required: (values, request, response) ->
    success = true
    for name in values when not request.parameters[name]?
      success = false
      response.json message: "#{name} is required", 400
      break
    success
