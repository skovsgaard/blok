{exec} = require 'child_process'

task 'build', 'Build from src/* to lib/*.js', ->
  exec 'coffee --compile --output lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log "Built okay!\n#{stdout + stderr}"

task 'run', 'Launch the app', ->
  exec 'node lib/app.js', (err, stdout, stderr) ->
    throw err if err
    #console.log stdout + stderr
