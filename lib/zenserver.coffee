"use strict"

# Libraries
http          = require "http"
https         = require "https"
url           = require "url"
querystring   = require "querystring"

ZenServer     = require "./zen"


module.exports =
  run: ->
    app = new ZenServer port = 8000

    app.get "/api", (request, response, next) ->
      response.end()

    app.get "/user/:id", (request, response, next) ->
      response.end()

    app.get "/domain/:id/:context", (request, response, next) ->
      if request.required ["name"]
        response.json request.parameters

    app.post "/domain/:id/:context", (request, response, next) ->
      response.end()

    # app.post "/api", (request, response, next) ->

    # app.put "/api", (request, response, next) ->

    # app.delete "/api", (request, response, next) ->
