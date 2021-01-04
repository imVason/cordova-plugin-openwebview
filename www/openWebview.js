var exec = require('cordova/exec');

exports.open = function (options, success, error) {
    exec(success, error, 'openWebview', 'open', [options]);
};