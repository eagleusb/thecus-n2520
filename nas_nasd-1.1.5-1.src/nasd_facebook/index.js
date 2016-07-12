'use strict';

function Facebook() {
    events.EventEmitter.call(this);
    
    var me = this,
        querystring = require('querystring');
    
    function post(image, message, token, fn) {
        var params = querystring.stringify({
                'access_token': token,
                'message': message
            }),
            url = 'https://graph.facebook.com/me/photos?' + params,
            request = new Nasd.CUrl('-s', '-F', 'source=@' + image, url);
        
        request.on('data', function (data) {
            fn(null, JSON.parse(data));
        });

        request.on('error', function () {
            fn('error');
        });
    }

    me._async_method = {
        post: post
    }
}
inherits(Facebook, events.EventEmitter);

module.exports = new Facebook();

