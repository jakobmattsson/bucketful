fs = require 'fs'
path = require 'path'
should = require 'should'
jscov = require 'jscov'
_ = require 'underscore'
config = require jscov.cover('..', 'src', 'load-config')

describe 'load-config', ->

  describe 'load', ->

    it 'sets default values for all options', () ->
      setCNAME = ->
      thePlugin = {
        create: -> { setCNAME: setCNAME }
        namespace: 'whateverPlug'
      }
      load = config.createLoader({
        loadPlugin: (plugin) -> thePlugin
        userConfigPath: path.resolve(__dirname, 'config/non-existing.json')
      })

      userConfig = { bucketful: {} }

      defaults = [
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

      # dnsProvider is different
      dnsProvider = process.env['bucketful__dnsProvider'] || userConfig.bucketful.dnsProvider
      if dnsProvider
        outExpect.dnsProvider = {
          username: process.env['whateverPlug__username'] || userConfig.whateverPlug?.username
          password: process.env['whateverPlug__username'] || userConfig.whateverPlug?.username
          setCNAME: thePlugin.create().setCNAME
          namespace: 'whateverPlug'
        }
      else
        outExpect.dnsProvider = undefined

      load({}).should.eql(outExpect)





  it 'sets default values for all options', () ->
    setCNAME = ->
    thePlugin = {
      create: -> { setCNAME: setCNAME }
      namespace: 'someplugin'
    }
    load = config.createLoader({
      loadPlugin: (plugin) -> thePlugin
      userConfigPath: path.resolve(__dirname, 'config/bucketful-userConfig.json')
    })

    userConfig = {
      bucketful: {
        dnsProvider: "myProvider"
        region: "eu-west-1"
      }
      someplugin: {
        username: 'daName'
      }
    }

    defaults = [
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

    # dnsProvider is different
    dnsProvider = process.env['bucketful__dnsProvider'] || userConfig.bucketful.dnsProvider
    if dnsProvider
      outExpect.dnsProvider = {
        username: process.env['someplugin__username'] || userConfig.someplugin?.username
        password: process.env['someplugin__password'] || userConfig.someplugin?.password
        setCNAME: thePlugin.create().setCNAME
        namespace: 'someplugin'
      }
    else
      outExpect.dnsProvider = undefined

    load({}).should.eql(outExpect)
