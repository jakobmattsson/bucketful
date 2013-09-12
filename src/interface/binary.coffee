process.on 'uncaughtException', (err) ->
  console.log('Uncaught exception!', err?.message || err)

optimist = require 'optimist'
bucketful = require './api'
help = require '../implementation/help'

type = 'help' if optimist.argv.help
type = 'version' if optimist.argv.version

help.binaryMeta type, process.stdout, ->
  conf = bucketful.load()
  conf.output = process.stdout
  bucketful.deploy conf, (err) ->
    console.log()
    if err
      console.log(err)
      process.exit(1)
