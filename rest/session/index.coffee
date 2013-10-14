
"use strict"

require 'js-yaml'
http = require 'http'
conf = require "./conf.yaml"
path = require 'path'
fs   = require 'fs'
os   = require 'options-stream'

basePath = process.env.PWD

working  = true

initProcess  = ( index ) ->
  sockFile   = path.join basePath, 'run', "#{conf.app_name}_#{index}.sock"
  if fs.existsSync sockFile
    fs.unlinkSync sockFile

  app = http.createServer ( req, res ) ->
    resContent = 'session'+index
    res.end resContent
  app.listen sockFile

process.on 'message', ( eventName ) ->
  if eventName.indexOf( 'startserver' ) >= 0
    param = eventName.split '|'
    initProcess param[ 1 ]
