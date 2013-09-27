
"use strict"

net        = require 'net'
http       = require 'http'
justlog    = require 'justlog'
os         = require 'options-stream'
mkdirp     = require 'mkdirp'
path       = require 'path'
ep         = require 'parevents'
fs         = require 'fs'
listener   = require './listener'
cp         = require 'child_process'
proxy      = require './reverseProxy'
stream     = require 'stream'

class AllInOne

  processesPool : {}

  constructor : ( options, callback = -> ) ->
    @options = options = @_mergerOptions( options )
    @_init options, callback

  _mergerOptions : ( options ) ->
    opts = {}
    os options, opts

  _init : ( options, callback ) ->
    that = this
    pipe = ep( [
      ->
        that._initFloders(
          options.run_dir,
          options.log_dir,
          @
        )
      ->
        that._initLogs options.log_dir, @
      ->
        that._initSock options.mastersock, @
      ->
        that._initPid options.masterpid, @
      ->
        that._initProxy
          processesPool : @processesPool
        , @
      ->
        that._initListener {}, @
    ] );
    pipe.on 'drain', callback
    pipe.run()

  _initFloders : ( floders..., cb ) ->
    pipes = []
    that  = @
    for floder in floders
      pipes.push do ( floder )->
        ->
          mkdirp path.join( __dirname, floder ), @

    pipe = ep( pipes ).on 'drain', cb
    pipe.run()
    
  _initLogs : ( log_dir, cb )->
    @log = null
    log_dir = path.join __dirname, log_dir
    if log_dir
      @log = justlog
        file :
          level   : justlog.ERROR | justlog.INFO
          path    : "[#{log_dir}/master-]YYYY-MM-DD[.log]"
          pattern : "file"
        stdio : false
    process.nextTick cb if cb

  _initSock : ( sockfile, cb ) ->
    that  = @
    sockfile = path.join __dirname, sockfile
    if fs.existsSync sockfile
      fs.unlinkSync sockfile
    @sock = sock = net.createServer ( c ) =>
      @log.info 'new work connected!'
      c.on 'end', () ->
        that.log.info 'disconnected!'
      c.on 'data', ( data ) ->
        conf = JSON.parse data.toString()
        that._startWorker conf, c, ->
          that.log.info "app #{conf.appName} start success"
          c.write JSON.stringify
            returnCode : 0
            message    : "app #{conf.appName} start success"

    sock.listen sockfile, ( err ) =>
      if err
        @log.error err
      else 
        @log.info 'sock bound!'
      process.nextTick cb if cb

  _initPid : ( file, cb ) ->
    fs.writeFile path.join( __dirname, file ), process.pid, cb

  _initListener : ( conf, cb ) ->
    @listener = listener( conf, cb )

  _initProxy : ( conf, cb ) ->
    @proxy = proxy 
      processesPool : @processesPool
    , cb

  _startWorker : ( conf, connect, cb ) ->
    { appFile }    = conf
    try
      appConfFile  = "#{path.dirname appFile}/conf.yaml"
      appConf      = require appConfFile
    catch e
      connect.write JSON.stringify
        returnCode : 1
        message    : e.message
      connect.end()
      return
    { process_num, middleware, app_name }  = appConf
    if @processesPool[ middleware ]
      usedAppName = @processesPool[ middleware ].appName
      connect.write JSON.stringify
        returnCode : 1
        message    : "the middleware #{middleware} was used by #{usedAppName}"
      connect.end()
      @log.info "app: #{app_name} start refused, because of this middleware #{middleware} was used by #{usedAppName}"
      return
    process_num    = 1 if !process_num?
    processes      = []
    for i in [ 0...process_num ]
      processes.push cp.fork appFile
    @processesPool[ middleware ] = 
      appName   : app_name
      appFile   : appFile
      processes : processes
    process.nextTick cb if cb

  _distributeMission : ( subApp, req, res ) ->
    { appName } = subApp
    proxy = http.request
      socketPath : path.join __dirname, @options.run_dir, "#{appName}.sock"
      headers    : req.headers
      method     : req.method
      path       : req.url
    , ( proxyRes ) ->
      proxyRes.pipe res
    req.pipe proxy

  start : () ->
    socket = null
    app    = http.createServer ( req, res ) =>
      subApp = @proxy.getApp req, res
      if subApp isnt false
        @_distributeMission subApp, req, res
    app.listen @options.port, ( err ) =>
      if err
        @log.error err.message
      else
        @log.info "master server start listening at #{@options.port}"

  close : ( cb ) ->
    @sock.close()
    process.nextTick cb if cb

exports = module.exports = ( options, callback ) ->
  new AllInOne options, callback
  