request = require 'request'

exports.get_recent_url_for = (notification) ->
    if notification.object_type is 'tag'
        return ""
    else if notification.object_type is 'geo'
        return ""
    else
        return null

exports.delete_all = (callback) ->
    request.del "https://api.instagram.com/v1/subscriptions?client_secret=#{process.env.CLIENT_SECRET}&object=all&client_id=#{process.env.CLIENT_ID}", (error, response, body) ->
        callback(error, body)

exports.list_all = (callback) ->
    request "https://api.instagram.com/v1/subscriptions?client_secret=#{process.env.CLIENT_SECRET}&client_id=#{process.env.CLIENT_ID}", (error, response, body) ->
        callback(error, body)

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
        callback error, body