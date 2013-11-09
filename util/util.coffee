
"use strict"

util = null

class Util

  output : ( returnCode = 0, message = '', returnValue = '' ) ->
    JSON.stringify
      returnCode  : +returnCode
      returnMsg   : message
      returnValue : returnValue

  input : ( data, success, fail ) ->
    fail     = ( () -> ) if !fail?
    data     = data.toString()
    try
      result = JSON.parse data
    catch e
      console.log "error:#{e.stack}"
      return
    if result.returnCode is 0
      success result.returnValue, result.returnMsg
    else
      fail result.returnMsg, result.returnValue

exports = module.exports = () ->
  if util then util else util = new Util