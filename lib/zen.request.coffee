"use strict"

module.exports =

  session: (request)->
    session = undefined
    key = global.ZEN.session?.authorization
    session = request.headers[key] if key? and request.headers[key]?
    request.headers.cookie?.split(";").forEach (cookie) ->
      parts = cookie.split("=")
      key = parts[0].trim()
      session = (parts[1] or "").trim() if key is global.ZEN.session?.cookie
    session

  required: (values, request, response) ->
    success = true
    for name in values when not request.parameters[name]?
      success = false
      response.json message: "#{name} is required", 400
      break
    success

  multipart: (error, parameters, files) ->
    for field, values of files
      if Array.isArray(values)
        parameters[field] = (_file(value) for value in values when value.size > 0)
      else if values.size > 0
        parameters[field] = _file(values)
    parameters

_file = (data) ->
  return {
    name: data.name
    type: data.type
    path: data.path
    size: data.size
  }
