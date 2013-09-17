connect      = require 'connect'
pm           = require 'pm'
path         = require 'path'
fs           = require 'fs'

class AllInOne

  constructor : () ->

  start : () ->
    
  close : ( cb ) ->
    cb?()

exports = module.exports = () ->
  return new AllInOne
