"use strict"

fs            = require "fs"
yaml          = require "js-yaml"
path          = require "path"
node_package  = require "../package.json"
colors        = require "colors"

module.exports = do ->
  # -- ZEN config file ---------------------------------------------------------
  file = path.join __dirname, "../../../#{process.argv[2] or 'zen'}.yml"
  ZEN = yaml.safeLoad fs.readFileSync(file, "utf8")

  # -- ZEN environment (if exists) ---------------------------------------------
  ZEN.type = process.argv[3] or ZEN.environment
  if ZEN.type
    file = path.join __dirname, "../../../environment/#{ZEN.type}.yml"
    environment = yaml.safeLoad fs.readFileSync(file, "utf8")
    ZEN[attribute] = value for attribute, value of environment

  # -- ZEN port ----------------------------------------------------------------
  ZEN.port = process.argv[4] or process.env.PORT or 1337

  # -- ZEN timezone ------------------------------------------------------------
  process.env.TZ = ZEN.timezone if ZEN.timezone

  # -- ZEN output ------------------------------------------------------------
  process.stdout.write "\u001B[2J\u001B[0;0f"
  console.log "========================================================================"
  console.log " ZENserver v#{node_package.version}", "- Easy (but powerful) NodeJS server".grey
  console.log " https://github.com/soyjavi/zen-server".grey
  console.log "========================================================================"
  console.log " ▣ ENVIRONMENT"
  console.log " ✓".green, "Environment".grey,  ZEN.type
  console.log " ✓".green, "Address".grey, "#{ZEN.host}:#{ZEN.port}"
  console.log " ✓".green, "Timezone".grey, ZEN.timezone

  ZEN.br = (heading) ->
    console.log "------------------------------------------------------------------------".grey
    console.log " ▣ #{heading}" if heading

  global.ZEN = ZEN
