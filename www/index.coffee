"use strict"

module.exports = (zen) ->

  zen.get "/www/:domain", (request, response, next) ->
    data =
      title : "zenserver"
      author:
        name    : request.parameters.domain
        twitter : "@soyjavi"
    response.page "index", data, ["partial"]

  zen.get "/www", (request, response, next) ->
    data =
      title : "zenserver"
      author:
        name    : "Javi Jiménez"
        twitter : "@soyjavi"
    response.page "index", data, ["partial"]

