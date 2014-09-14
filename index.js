"use strict";

var CoffeeScript  = require('coffee-script');
var fs            = require("fs");
var yaml          = require('js-yaml');
var path          = require('path');

// -- Register CoffeeScript if exits -------------------------------------------
if(CoffeeScript.register) CoffeeScript.register();


// -- Get endpoints ------------------------------------------------------------
var directory = '../../'
var directory = ""
var endpoint_file = process.argv[2] === undefined ? "zen" : process.argv[2];
var endpoint_path = path.join(__dirname, directory + endpoint_file + ".yml");
console.log(endpoint_file ,endpoint_path)
global.config = yaml.safeLoad(fs.readFileSync(endpoint_path, 'utf8'));
// console.log(global.config);

// -- Run ----------------------------------------------------------------------
// module.exports = require('./lib/zenserver');
require('./lib/zenserver').run();
