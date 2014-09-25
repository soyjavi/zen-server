"use strict"

fs       = require "fs"
path     = "#{__dirname}/../../../logs"

class LogFile

  @buffer : {}

  constructor: (@file, interval = 60000) ->
    fs.mkdirSync path unless fs.existsSync path
    @constructor.buffer[@file] = []
    @interval = setInterval =>
      if @constructor.buffer[@file].length > 0
        buffer =  @constructor.buffer[@file]
        @constructor.buffer[@file] = []
        fs.appendFile "#{path}/#{@file}.#{_date()}.json", buffer
    , interval

  append: (values = {}) ->
    @constructor.buffer[@file].push JSON.stringify values

  clean: ->
    clearInterval @interval
    @constructor.buffer[@file] = []

module.exports = LogFile

_date = -> (new Date()).toISOString().slice(0,10).replace(/-/g,"")
