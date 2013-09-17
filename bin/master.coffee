"use strict"

require 'js-yaml'

fs      = require 'fs'
path    = require 'path'
aio     = require '../lib/aio-server'
options = require '../conf/conf.yaml'

web = aio options

# onquit
quit = ->
  return if quit.flag
  quit.flag = true

  web.close ->
    console.log "Master Server Quit."
    process.exit();
  quit.timer = setTimeout ->
    console.log 'Close Timeout'
    process.exit();
  , 10000

process.on 'SIGINT',  quit
process.on 'SIGQUIT', quit
process.on 'exit',    quit

process.on 'uncaughtException', (err)->
  console.log err
  console.log "---------"
  console.log err.stack
  quit()
  
web.start ( port ) ->
  console.log 'listening:', port
