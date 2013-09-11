optimist = require 'optimist'
options = require './options'
packageData = require '../package.json'

exports.getHelpText = ->

  options.forEach ({ name, desc, defaultValue }) ->
    optimist.describe(name, desc)

  optimist
    .usage(packageData.description)
    .describe("version", "Print the current version number")
    .describe("help", "Show this help message")
    .alias("version", "v")
    .alias("help", "h")

  optimist.help().split('\n').map((x) -> x.trimRight()).join('\n')
