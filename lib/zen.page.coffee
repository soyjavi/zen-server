"use strict"

fs       = require "fs"
mustache = require "mustache"


module.exports = (file, data, partials = []) ->
  files = {}
  files[partial] = __mustache partial for partial in partials or []
  @html mustache.to_html __mustache(file), data, files


__mustache = (file) ->
  dir = "#{__dirname}/../../../www/mustache/"
  try
    fs.readFileSync "#{dir}#{file}.mustache", "utf8"
  catch error
    try
      fs.readFileSync "#{dir}404.mustache", "utf8"
    catch error
      "<h1> 404 - Not found</h1>"
