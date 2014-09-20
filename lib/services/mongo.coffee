###
ZENserver
@description  Easy (but powerful) NodeJS Server
@author       Javi Jimenez Villar <@soyjavi>

@namespace    lib/services/mongo
###
"use strict"

mongoose = require "mongoose"
Hope     = require "hope"

module.exports =
  connections: {}

  open: (connection = {}) ->
    if Object.keys(@connections).length is 0
      global.ZEN.br "MONGODB"

    promise = new Hope.Promise()
    url = connection.host + ":" + connection.port + "/" + connection.db
    if connection.user and connection.password
      url = connection.user + ":" + connection.password + "@" + url

    @connections[connection.name] = mongoose.createConnection "mongodb://#{url}"
    @connections[connection.name].on "error", (error) ->
      console.log " ⚑".red, "Error connection:".grey, error.red

      promise.done true, null
      process.exit()
    @connections[connection.name].on "connected", (error) ->
      console.log " ✓".green, connection.name, "listening at".grey, "#{connection.host}:#{connection.port}/#{connection.db}".underline.blue
      promise.done null, true
    promise

  close: ->
    for name of @connections
      @connections[name].close ->
        console.log "▣".green, "MONGO/#{name}".underline.green, "closed connection"
