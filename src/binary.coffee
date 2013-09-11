optimist = require 'optimist'
packageData = require '../package.json'
bucketful = require './bucketful'
help = require './help'

if optimist.argv.help
  console.log(help.getHelpText())
else if optimist.argv.version
  console.log(packageData.version)
else
  process.on 'uncaughtException', ->
    console.log('uncaught exception')
    console.log(arguments)

  conf = bucketful.load()
  conf.output = process.stdout
  bucketful.deploy conf, (err) ->
    console.log()
    if err
      console.log(err)
      process.exit(1)
