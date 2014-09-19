"use strict";

var CoffeeScript  = require('coffee-script');
// -- Register CoffeeScript if exits -------------------------------------------
if(CoffeeScript.register) CoffeeScript.register();

var Zen           = require('./lib/zen');

module.exports = {
    // Crawler     : require("./lib/helpers/crawler"),
    // Cron        : require("./lib/helpers/cron"),
    // Deploy      : require("./lib/helpers/deploy"),
    // Model       : require("./lib/helpers/model"),
    // Services
    // Mongo       : require("./lib/services/mongo"),
    // Redis       : require("./lib/services/redis"),
    // Appnima     : require("./lib/services/appnima"),
    // Facade
    // Mongoose    : require("mongoose"),
    // Hope        : require("hope"),
    // Instance
    start         : function() {
        return new Zen()
    }
};
