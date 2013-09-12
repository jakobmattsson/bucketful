optimist = require 'optimist'
packageData = require '../../package.json'
bucketful = require './api'
help = require '../implementation/help'

if optimist.argv.help
  console.log(help.getHelpText())
else if optimist.argv.version
  console.log(packageData.version)
else
  process.on 'uncaughtException', (err) ->
    console.log('Uncaught exception!', err?.message || err)

  conf = bucketful.load()
  conf.output = process.stdout
  bucketful.deploy conf, (err) ->
    console.log()
    if err
      console.log(err)
      process.exit(1)
