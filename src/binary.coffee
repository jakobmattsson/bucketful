fs = require 'fs'
path = require 'path'
optimist = require 'optimist'
_ = require 'underscore'
bucketful = require './bucketful'
options = require './options'
packageData = require '../package.json'

options.forEach ({ name, desc, defaultValue }) ->
  optimist.describe(name, desc)

optimist
  .usage(packageData.description)
  .describe("version", "Print the current version number")
  .describe("help", "Show this help message")
  .alias("version", "v")
  .alias("help", "h")
  .argv

if optimist.argv.help
  console.log(optimist.help())
else if optimist.argv.version
  console.log(packageData.version)
else
  process.on 'uncaughtException', ->
    console.log('uncaught exception')
    console.log(arguments)

  conf = bucketful.load()
  bucketful.deploy _.extend({}, conf, { output: process.stdout }), (err) ->
    console.log()
    if err
      console.log(err)
      process.exit(1)
