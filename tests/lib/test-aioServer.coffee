
"use strict"

expect    = require 'expect.js'
spawn     = require( 'child_process' ).spawn
aioServer = require '../../lib/aio-server'
path      = require 'path'
fs        = require 'fs'

options   =
  mastersock : '../mock/master.sock'
  run_dir    : '../mock/run_dir'
  log_dir    : '../mock/log_dir'

aio       = null

describe 'aio server', () ->

  before ( done ) ->
    aio   = new aioServer options, done

  after ( done ) ->
    # spawn 'rm', [ '-rf', options.run_dir ]
    # spawn 'rm', [ '-rf', options.log_dir ]
    done()

  it 'init aio server', ( done ) ->
    options = 
      mastersock : '../mock/master.sock'
      run_dir    : '../mock/run_dir'
      log_dir    : '../mock/log_dir'
    expect( JSON.stringify aio.getOptions() ).to.be JSON.stringify options
    expect( fs.existsSync path.join options.run_dir ).to.be.ok()
    expect( fs.existsSync path.join options.log_dir ).to.be.ok()
    done()

