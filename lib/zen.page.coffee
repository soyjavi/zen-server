"use strict"

mustache = require "mustache"
fs       = require "fs"

module.exports = (file, data, partials = []) ->
  directory = __dirname + '/../www/templates'
  file = fs.readFileSync "#{directory}/#{file}.mustache", "utf8"

  files = {}
  for partial in partials
    files[partial] = fs.readFileSync "#{directory}/#{partial}.mustache", "utf8"
  @html mustache.to_html file, data, files
