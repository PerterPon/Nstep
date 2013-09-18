
"use strict"

justlog    = require 'justlog'
os         = require 'options-stream'
mkdirp     = require 'mkdirp'
path       = require 'path'
ep         = require 'parevents'
net        = require 'net'
fs         = require 'fs'
connect    = require 'connect'
middleware = 

class AllInOne

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
      ,
      ->
        that._initLogs options.log_dir, @
      ,
      ->
        that._initSock options.mastersock, @
      ->
        that._initPid options.masterpid, @
    ] );
    pipe.on 'drain', callback
    pipe.run()

  _initFloders : ( floders..., cb ) ->
    pipes = []
    that  = @
    for floder in floders
      pipes.push do ( floder )->
        ->
          mkdirp floder, @

    pipe = ep( pipes ).on 'drain', cb
    pipe.run()
    
  _initLogs : ( log_dir, cb )->
    @log = null
    if log_dir
      @log = justlog
        file :
          level   : justlog.ERROR | justlog.INFO
          path    : "[#{log_dir}/master-]YYYY-MM-DD[.log]"
          pattern : "file"
        stdio : false
    cb?()

  _initSock : ( sockfile, cb ) ->
    if fs.existsSync sockfile
      fs.unlinkSync sockfile
    @sock = net.createServer ( c ) =>
      @log.info 'new work connected!'

    @sock.listen sockfile, () =>
      @log.info 'sock bound!'
      cb?()

  _initPid : ( file, cb ) ->
    fs.writeFile file, process.pid, cb

  start : () ->
    @app = connect()


  close : () ->
    @sock.close()
    # process.exit()

exports = module.exports = ( options, callback ) ->
  new AllInOne options, callback
