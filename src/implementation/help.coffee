optimist = require 'optimist'
options = require './options'
packageData = require '../../package.json'


getHelpText = ->

  options.forEach ({ name, desc, defaultValue }) ->
    optimist.describe(name, desc)

  optimist
    .usage(packageData.description)
    .describe("version", "Print the current version number")
    .describe("help", "Show this help message")
    .alias("version", "v")
    .alias("help", "h")

  optimist.help().split('\n').map((x) -> x.trimRight()).join('\n')


exports.binaryMeta = (type, output, callback) ->
  packageData = require '../../package.json'
  help = require '../implementation/help'

  if type == 'help'
    output.write(getHelpText() + '\n')
  else if type == 'version'
    output.write(packageData.version + '\n')
  else
    callback()
