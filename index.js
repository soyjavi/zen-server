"use strict";

require('coffee-script/register');
var Zen = require('./lib/zen');

module.exports = {
    // Services
    Mongo       : require("./lib/services/mongo"),
    Redis       : require("./lib/services/redis"),
    Appnima     : require("./lib/services/appnima"),
    // Facade
    Mongoose    : require("mongoose"),
    Hope        : require("hope"),
    Mustache    : require("mustache"),
    // Instance
    start         : function() {
        return new Zen()
    }
};
