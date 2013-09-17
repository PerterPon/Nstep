
"use strict"

justlog = require 'justlog'
os      = require 'options-stream'
mkdirp  = require 'mkdirp'

class AllInOne

  constructor : ( options, cb ) ->
    @options = options = @_mergerOptions( options )
    @_init options

  _mergerOptions : ( options ) ->
    opts = {}
    os options, opts

  _init : ( options ) ->
    @_initFloders(
      options.run_dir,
      options.log_dir
    )
    @_initLogs(  )
    @_initSock(  )

  _initFloders : ( floders... ) ->
    for floder in floders
      mkdirp floder

  _initLogs : ->


  _initSock : ->

  getOptions : ->
    @options

  start : () ->


  close : () ->



exports = module.exports = ( options, cb ) ->
  new AllInOne options, cb