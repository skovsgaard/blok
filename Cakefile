{exec} = require 'child_process'
{spawn} = require 'child_process'

task 'build', 'Build from src/* to lib/*.js', ->
  exec 'coffee --compile --output lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log "Built okay!\n#{stdout + stderr}"

task 'run', 'Launch the app', ->
  server = spawn 'node', ['lib/app.js']
  server.stdout.on 'data', (data) ->
    console.log data.toString()
  server.stderr.on 'data', (data) ->
    console.log data.toString()
