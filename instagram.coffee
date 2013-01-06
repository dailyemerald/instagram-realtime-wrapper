request = require 'request'

exports.buildTagSubscription = (host, tag, callback) ->
    requestObj = {
        method: 'POST',
        url: 'https://api.instagram.com/v1/subscriptions/',
        form: {
            'client_id': process.env.CLIENT_ID, 
            'client_secret': process.env.CLIENT_SECRET,
            'object': 'tag',
            'aspect': 'media', 
            'object_id': tag
            'callback_url': 'http://' + host + "/notify/" + tag
        }
    }
    request requestObj, (error, response, body) ->
        if error is null
            callback null, body
        else
            callback error, null