var exec = require('cordova/exec')

exports.login = function(permissions, s, f) {
    exec(s, f, 'ZaloLoginPlugin', 'login', permissions)
}
exports.logout = function(s, f) {
    exec(s, f, 'ZaloLoginPlugin', 'logout')
}