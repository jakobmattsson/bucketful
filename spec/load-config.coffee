fs = require 'fs'
path = require 'path'
should = require 'should'
jscov = require 'jscov'
_ = require 'underscore'
config = require jscov.cover('..', 'src', 'load-config')

describe 'load-config', ->

  describe 'load', ->

    it 'sets default values for all options', () ->
      userConfigFile = path.resolve(process.env.HOME, ".bucketful")
      if fs.existsSync(userConfigFile)
        userConfig = JSON.parse(fs.readFileSync(userConfigFile))
      else
        userConfig = { bucketful: {} }

      defaults = [
        ['dnsProvider', 'dnsProvider', undefined]
        ['s3bucket', 'bucket', undefined]
        ['targetDir', 'targetDir', undefined]
        ['aws_key', 'key', undefined]
        ['aws_secret', 'secret', undefined]
        ['region', 'region', undefined]
        ['siteIndex', 'websiteIndex', 'index.html']
        ['siteError', 'websiteError', 'index.html']
      ]

      outExpect = _.object defaults.map ([outname, key, defaultValue]) ->
        [outname, process.env['bucketful__' + key] || userConfig.bucketful[key] || defaultValue]

      config.load({}).should.eql(outExpect)
