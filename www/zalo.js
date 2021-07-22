var exec = require('cordova/exec')

exports.login = function (permissions, s, f) {
    exec(s, f, 'ZaloLoginPlugin', 'login', permissions)
}
