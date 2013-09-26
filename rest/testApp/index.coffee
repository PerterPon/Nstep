
"use strict"

require 'js-yaml'
http = require 'http'
conf = require './conf.yaml'
path = require 'path'
fs   = require 'fs'
os   = require 'options-stream'

basePath = process.env.PWD

do initProcess  = () ->
  sockFile   = path.join basePath, 'run', "#{conf.app_name}.sock"
  if fs.existsSync sockFile
    fs.unlinkSync sockFile

  app  = http.createServer ( req, res ) ->
    res.end 'test app!'
  app.listen sockFile
