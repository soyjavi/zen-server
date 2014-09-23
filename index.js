"use strict";

var CoffeeScript  = require('coffee-script');
// -- Register CoffeeScript if exits -------------------------------------------
if(CoffeeScript.register) CoffeeScript.register();

var Zen           = require('./lib/zen');

module.exports = {
    // Services
    Mongo       : require("./lib/services/mongo"),
    Redis       : require("./lib/services/redis"),
    Appnima     : require("./lib/services/appnima"),
    // Facade
    Mongoose    : require("mongoose"),
    Hope        : require("hope"),
    // Instance
    start         : function() {
        return new Zen()
    }
};
