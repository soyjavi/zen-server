"use strict";

var CoffeeScript= require('coffee-script');

// Register CoffeeScript if exits
if(CoffeeScript.register) CoffeeScript.register();

// Read config
// module.exports = require('./lib/zenserver');
require('./lib/zenserver').run();
