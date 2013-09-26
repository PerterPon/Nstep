
"use strict"

os   = require 'options-stream'

class ReverseProxy

  processesPool : {}

  constructor : ( conf, cb ) ->
    { @processesPool } = conf
    process.nextTick cb if cb

  getApp : ( req, res ) ->
    url = req.url
    [ point, middleware ] = url.split '/'
    app = @processesPool[ middleware ]
    if app is undefined
      res.end '404'
    else
      return app

exports = module.exports  = ( conf, cb ) ->
  new ReverseProxy conf, cb