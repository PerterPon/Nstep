
EventEmitter = require( 'events' ).EventEmitter

class Listener extends EventEmitter

  constructor : ( options, cb ) ->
    cb?()


exports = module.exports = ( options, cb ) ->
  new Listener options, cb