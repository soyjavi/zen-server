"use strict"

# Libraries
ZenServer     = require "./zen"



module.exports =
  run: ->
    zen = new ZenServer port = global.ZEN.port

    for context in ["api", "www"]
      for endpoint in global.ZEN[context] or []
        require("../../../#{context}/#{endpoint}") zen
