"use strict"

os = require 'options-stream'

class ReverseProxy

  processesPool : {}

  constructor : ( conf, cb ) ->
    { @processesPool } = conf
    process.nextTick cb if cb 

  getApp : ( req, res ) ->
    url      = req.url
    finished = false
    res.on 'finish', () ->
      finished = true
    [ point, middleware ] = url.split '/'
    if middleware is 'favicon.ico' or ( apps = @processesPool[ middleware ] ) is undefined or apps.length is 0
      return false
    # apps     = @processesPool[ middleware ]
    # if !apps || !apps.length
    #   return false
    for app in apps
      if finished
        res.end = () ->
        return
      { refused } = app if app
      if ( app is undefined ) or ( refused is true )
        return false
      else
        return app

exports = module.exports  = ( conf, cb ) ->
  new ReverseProxy conf, cb
