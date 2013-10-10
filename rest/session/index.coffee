
"use strict"

require 'js-yaml'
http = require 'http'
conf = require "./conf.yaml"
path = require 'path'
fs   = require 'fs'
os   = require 'options-stream'

basePath = process.env.PWD

working  = true

do initProcess  = () ->
  sockFile   = path.join basePath, 'run', "#{conf.app_name}.sock"
  if fs.existsSync sockFile
    fs.unlinkSync sockFile

  app = http.createServer ( req, res ) ->
    resContent   = ''
    if req.headers[ 'x-nstep-stopserver' ]
      working    = false
      resContent = 'success'
    else if req.headers[ 'x-nstep-startserver' ]
      working    = true
      resContent = 'success'
    if resContent isnt ''
      res.end resContent
      return
    if working
      resContent = 'session'
    else 
      resContent = '404'
    res.end resContent
  app.listen sockFile
