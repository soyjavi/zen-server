"use strict"

fs       = require "fs"
path     = "#{__dirname}/../../../monitor"

class Monitor

  @buffer : {}

  constructor: (@file, interval = 60000) ->
    fs.mkdirSync path unless fs.existsSync path
    @constructor.buffer[@file] = []
    @interval = setInterval =>
      if @constructor.buffer[@file].length > 0
        buffer =  @constructor.buffer[@file] or []
        @constructor.buffer[@file] = []
        file_name = "#{path}/#{@file}.#{_date()}.json"
        fs.readFile file_name, "utf8", (error, data) =>
          data = if error or data?.length is 0 then [] else JSON.parse data
          data = data.concat buffer
          fs.writeFile file_name, JSON.stringify(data, null, 0), "utf8"
    , interval

  append: (values = {}) ->
    @constructor.buffer[@file].push JSON.stringify values

  clean: ->
    clearInterval @interval
    @constructor.buffer[@file] = []

module.exports = Monitor

_date = -> (new Date()).toISOString().slice(0,10).replace(/-/g,"")
