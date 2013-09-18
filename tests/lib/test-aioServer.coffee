
"use strict"

expect    = require 'expect.js'
spawn     = require( 'child_process' ).spawn
aioServer = require '../../lib/aio-server'
path      = require 'path'
fs        = require 'fs'

options   =
  mastersock : path.join __dirname, '../mock/run_dir/master.sock'
  masterpid  : path.join __dirname, '../mock/run_dir/master.pid'
  run_dir    : path.join __dirname, '../mock/run_dir'
  log_dir    : path.join __dirname, '../mock/log_dir'

aio       = null

addZero   = ( v ) ->
  v = +v
  if v < 10
    v = "0#{v}"
  v

describe 'aio server', () ->

  before ( done ) ->
    aio   = new aioServer options, done

  after ( done ) ->
    aio.close()
    spawn 'rm', [ '-rf', options.run_dir ]
    spawn 'rm', [ '-rf', options.log_dir ]

    done()

  it 'init aio server', ( done ) ->
    expect( fs.existsSync options.run_dir ).to.be.ok()
    expect( fs.existsSync options.log_dir ).to.be.ok()
    done()

  it 'init log', ( done ) ->
    date    = new Date
    year    = date.getFullYear()
    month   = addZero date.getMonth() + 1
    day     = addZero date.getDate()
    logFile = "#{options.log_dir}/master-#{year}-#{month}-#{day}.log"
    expect( fs.existsSync logFile ).to.be.ok()
    done()

  it 'init domain sock', ( done ) ->
    expect( fs.existsSync options.mastersock ).to.be.ok()
    done()

  it 'init pid file', ( done ) ->
    expect( fs.existsSync options.masterpid ).to.be.ok()
    done()


