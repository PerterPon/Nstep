fs   = require 'fs'
path = require 'path'
util = require '../util/util'
EventEmitter = require( 'events' ).EventEmitter

PROCESS      = process

class Worker extends EventEmitter

  constructor : ->
    @initEvents()

  initEvents : ->
    PROCESS.on 'message', @onMessage

    PROCESS.on 'exit', ->
      self._kill()
    PROCESS.on 'SIGTERM', ->
      self._kill()
    PROCESS.on 'SIGHUB', ->
      self._kill()
    PROCESS.on 'SIGINT', ->
      self._kill()
    PROCESS.on ''

  onMessage : ( message ) ->
    if ( message.indexOf 'startServer' ) is 0
      index = message.split( '|' )[ 1 ]
    else
      process.send util.output 1, "Invalid command : #{message}"

  start : ->
