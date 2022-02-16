#!/usr/bin/env node

'use strict';

var fs = require('fs');

var getPreferenceValue = function(config, name) {
    var value = config.match(new RegExp('name="' + name + '" value="(.*?)"', "i"))
    if (value && value[1]) {
        return value[1]
    } else {
        return null
    }
}

if (process.argv.join("|").indexOf("ZALO_APP_ID=") > -1) {
    var ZALO_APP_ID = process.argv.join("|").match(/ZALO_APP_ID=(.*?)(\||$)/)[1]
} else {
    var config = fs.readFileSync("config.xml").toString()
    var ZALO_APP_ID = getPreferenceValue(config, "ZALO_APP_ID")
}

var files = []

for (var i in files) {
    try {
        var contents = fs.readFileSync(files[i]).toString()
        fs.writeFileSync(files[i], contents.replace(/ZALO_APP_ID/g, ZALO_APP_ID))
    } catch (err) {}
}