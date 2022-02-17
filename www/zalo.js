var exec = require('cordova/exec')

exports.login = function(permissions, s, f) {
    exec(s, f, 'ZaloLoginPlugin', 'login', permissions)
}
exports.logout = function(s, f) {
    exec(s, f, 'ZaloLoginPlugin', 'logout')
}

exports.echo = function(arg0, success, error) {
    exec(success, error, 'ZaloLoginPlugin', 'echo', [arg0]);
};