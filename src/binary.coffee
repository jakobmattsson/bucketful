fs = require 'fs'
path = require 'path'
optimist = require 'optimist'
_ = require 'underscore'
bucketful = require './bucketful'

args = [
  { name: 'source',  desc: "Directory to use as starting point for the upload" }
  { name: 'bucket',  desc: "S3 bucket used as target for the upload" }
  { name: 'key',     desc: "AWS access key" }
  { name: 'secret',  desc: "AWS access secret" }
  { name: 'region',  desc: "AWS region to create the bucket in (defaults to 'us-east-1')" }
  { name: 'index',   desc: "File to use as index page (defaults to 'index.html')" }
  { name: 'error',   desc: "File to use as error page" }
  { name: 'dns',     desc: "The name of a bucketful plugin for configuring a CNAME" }
  { name: 'configs', desc: "Configuration files (defaults to 'package.json;config.json')" }
]

args.forEach ({ name, desc, defaultValue }) ->
  optimist.describe(name, desc)

optimist
  .usage("Deploys websites to Amazon S3")
  .describe("version", "Print the current version number")
  .describe("help", "Show this help message")
  .alias("version", "v")
  .alias("help", "h")
  .argv

if optimist.argv.help
  console.log(optimist.help())
else if optimist.argv.version
  console.log(require('../package.json').version)
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
