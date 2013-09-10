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
        ['bucket', 'bucket', undefined]
        ['source', 'source', undefined]
        ['key', 'key', undefined]
        ['secret', 'secret', undefined]
        ['region', 'region', undefined]
        ['index', 'index', 'index.html']
        ['error', 'error', 'index.html']
      ]

      outExpect = _.object defaults.map ([outname, key, defaultValue]) ->
        [outname, process.env['bucketful__' + key] || userConfig.bucketful[key] || defaultValue]

      # dns is different
      dns = process.env['bucketful__dns'] || userConfig.bucketful.dns
      if dns
        outExpect.dns = {
          username: process.env['whateverPlug__username'] || userConfig.whateverPlug?.username
          password: process.env['whateverPlug__username'] || userConfig.whateverPlug?.username
          setCNAME: thePlugin.create().setCNAME
          namespace: 'whateverPlug'
        }
      else
        outExpect.dns = undefined

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
        dns: "myProvider"
        region: "eu-west-1"
      }
      someplugin: {
        username: 'daName'
      }
    }

    defaults = [
      ['bucket', 'bucket', undefined]
      ['source', 'source', undefined]
      ['key', 'key', undefined]
      ['secret', 'secret', undefined]
      ['region', 'region', undefined]
      ['index', 'index', 'index.html']
      ['error', 'error', 'index.html']
    ]

    outExpect = _.object defaults.map ([outname, key, defaultValue]) ->
      [outname, process.env['bucketful__' + key] || userConfig.bucketful[key] || defaultValue]

    # dns is different
    dns = process.env['bucketful__dns'] || userConfig.bucketful.dns
    if dns
      outExpect.dns = {
        username: process.env['someplugin__username'] || userConfig.someplugin?.username
        password: process.env['someplugin__password'] || userConfig.someplugin?.password
        setCNAME: thePlugin.create().setCNAME
        namespace: 'someplugin'
      }
    else
      outExpect.dns = undefined

    load({}).should.eql(outExpect)
