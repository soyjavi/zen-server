"use strict";

var CoffeeScript  = require('coffee-script');
var fs            = require("fs");
var yaml          = require('js-yaml');
var path          = require('path');

// -- Register CoffeeScript if exits -------------------------------------------
if(CoffeeScript.register) CoffeeScript.register();

// -- ZEN config file ----------------------------------------------------------
var directory = '../../'
var config_file = process.argv[2] === undefined ? "zen" : process.argv[2];
var config_path = path.join(__dirname, directory + config_file + ".yml");
global.ZEN = yaml.safeLoad(fs.readFileSync(config_path, 'utf8'));

// -- ZEN environment (if exists) ----------------------------------------------
if (global.ZEN.environment) {
    var environment_name = process.argv[3] === undefined ? global.ZEN.environment : process.argv[3];
    var environment_path = path.join(__dirname, directory + '/environment/' + environment_name + ".yml");
    global.ZEN.environment = yaml.safeLoad(fs.readFileSync(environment_path, 'utf8'));
}

if (global.ZEN.environment.timezone) process.env.TZ = global.ZEN.environment.timezone;

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
    run         : function(callback) {
        return require("./lib/zenserver").run();
    }
};
