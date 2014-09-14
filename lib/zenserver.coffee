"use strict"

# Libraries
ZenServer     = require "./zen"

module.exports =
  run: ->
    zen = new ZenServer port = 8000

    require("../www/index") zen
    require("../api/index") zen
