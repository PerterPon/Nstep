
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

  processesPool    : {}

  processesPoolByName : {}

  psHashName       : {}

  psHashMiddleware : {}

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
        that._initEvents {}, @
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

  _initEvents : ( options, cb ) ->
    process.on 'error', () ->

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
      @log  = justlog
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
        that._workerHelper conf, c

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

  _workerHelper : ( conf, connect ) ->
    this[ "_#{conf.action}Worker" ]( conf, ( returnCode = 0, message = '' ) ->
      connect.write JSON.stringify
        returnCode : returnCode
        message    : message
      connect.end()
    )

  _startWorker : ( conf, cb ) ->
    { app_file, middleware } = conf
    try
      appConfFile  = "#{path.dirname app_file}/conf.yaml"
      appConf      = require appConfFile
    catch e
      connect.write JSON.stringify
        returnCode : 1
        message    : e.message
      connect.end()
      return
    { process_num, app_name }  = appConf
    if @processesPool[ middleware ]
      usedAppName = @processesPool[ middleware ].app_name
      connect.write JSON.stringify
        returnCode : 1
        message    : "the app name #{middleware} was already exists"
      connect.end()
      @log.error "app: #{app_name} start refused, because of this name #{middleware} was already exists."
      return
    process_num    = 1 if !process_num?
    processes      = []
    for i in [ 0...process_num ]
      processes.push ps = cp.fork app_file
      ps.process_index  = i
      ps.send "startserver|#{i}"
    middleware     = conf.middleware
    @processesPoolByName[ app_name ] = @processesPool[ middleware ] =
      middleware : middleware
      app_name   : app_name
      app_file   : app_file
      processes  : processes
    process.nextTick cb if cb

  _stopWorker : ( conf, cb ) ->
    { app_name }   = conf
    { middleware } = @processesPoolByName[ app_name ].middleware
    processes = @processesPool[ middleware ].processes
    for ps in processes
      ps.kill()
    @log.info "app: #{app_name} stoped!"
    delete @processesPool[ middleware ]
    delete @processesPoolByName[ app_name ]
    process.nextTick cb if cb

  _pauseWorkder : ( conf, cb ) ->
    { app_name }   = conf
    { middleware } = @processesPoolByName[ app_name ].middleware
    @processesPool[ middleware ].refused = true
    # { app_name } = conf
    # that = @
    # http.request
    #   socketPath : path.join __dirname, @options.run_dir, "#{app_name}.sock"
    #   headers    : {
    #     'x-nstep-stopserver' : 'true'
    #   }
    # , ( proxyRes ) ->
    #   if proxyRes is 'success'
    #     that.log.info 'pause app: #{app_name} success!'
    process.nextTick cb if cb

  _resumeWorkder : ( conf, cb ) ->
    { app_name }   = conf
    { middleware } = @processesPoolByName[ app_name ].middleware
    @processesPool[ middleware ].refused = true

    # { app_name } = conf
    # that = @
    # http.request
    #   socketPath : path.join __dirname, @options.run_dir, "#{app_name}.sock"
    #   headers    : {
    #     'x-nstep-startserver' : 'true'
    #   }
    # , ( proxyRes ) ->
    #   if proxyRes is 'success'
    #     that.log.info 'resume app: #{app_name} success!'
    process.nextTick cb if cb

  _distributeMission : ( subApp, req, res ) ->
    { processes, app_name } = subApp
    processes.push ps = processes.shift()
    { process_index:index } = ps
    proxy = http.request
      socketPath : path.join __dirname, @options.run_dir, "#{app_name}_#{index}.sock"
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
        if ( @_distributeMission subApp, req, res ) is false
          res.end '404'
      else
        res.end '404'
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
  