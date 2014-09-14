"use strict"

module.exports = (zen) ->

  zen.get "/api", (request, response, next) ->
    response.end()

  zen.get "/user/:id", (request, response, next) ->
    response.end()

  zen.get "/domain/:id/:context", (request, response, next) ->
    if request.required ["name"]
      response.json request.parameters

  zen.post "/domain/:id/:context", (request, response, next) ->
    response.end()

  zen.post "/api", (request, response, next) ->

  zen.put "/api", (request, response, next) ->

  zen.delete "/api", (request, response, next) ->

