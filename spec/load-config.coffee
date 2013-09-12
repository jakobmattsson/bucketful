async = require 'async'
fs = require 'fs'
path = require 'path'
should = require 'should'
tmp = require 'tmp'
jscov = require 'jscov'
_ = require 'underscore'
config = require jscov.cover('..', 'src', 'implementation/load-config')

propagate = (onErr, onSucc) -> (err, rest...) -> if err? then onErr(err) else onSucc(rest...)

describe 'load-config', ->

  describe 'load', ->

    it 'sets default values for all options, without a userConfig', () ->
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
        ['index', 'index', undefined]
        ['error', 'error', undefined]
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



    it 'sets default values for all options, including a userConfig', () ->

      userConfig = {
        bucketful: {
          dns: "myProvider"
          region: "eu-west-1"
        }
        someplugin: {
          username: 'daName'
        }
      }

      tmp.file (err, tmpFile) ->
        fs.writeFile tmpFile, JSON.stringify(userConfig), ->

          setCNAME = ->
          thePlugin = {
            create: -> { setCNAME: setCNAME }
            namespace: 'someplugin'
          }
          load = config.createLoader({
            loadPlugin: (plugin) -> thePlugin
            userConfigPath: tmpFile
          })

          defaults = [
            ['bucket', 'bucket', undefined]
            ['source', 'source', undefined]
            ['key', 'key', undefined]
            ['secret', 'secret', undefined]
            ['region', 'region', undefined]
            ['index', 'index', undefined]
            ['error', 'error', undefined]
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



    it 'prefers function arguments over file arguments', (done) ->
      tmp.file (err, tmpFile) ->

        load = config.createLoader({
          loadPlugin: (plugin) -> throw new Error("NO")
          userConfigPath: tmpFile
        })

        fileConf = {
          bucketful: {
            bucket: 'file.bucket1234'
            key: 'file.key'
          }
        }

        fs.writeFile tmpFile, JSON.stringify(fileConf), ->
          res = load({ bucket: 'function.bucket' })
          res.bucket.should.eql 'function.bucket'
          res.key.should.eql 'file.key'
          done()



    it 'accepts a configs parameter', (done) ->

      files = [
        bucketful: {
          bucket: 'file1'
          key: 'key!'
        }
      ,
        bucketful: {
          bucket: 'file2'
          secret: 'secret!'
        }
      ]

      load = config.createLoader({ })

      async.map files, (file, callback) ->
        tmp.file propagate callback, (tmpFile) ->
          fs.writeFile tmpFile, JSON.stringify(file), propagate callback, ->
            callback(null, tmpFile)
      , (err, temps) ->
        should.not.exist err
        res = load({
          configs: temps.join(';')
        })
        res.bucket.should.eql 'file1'
        res.key.should.eql 'key!'
        res.secret.should.eql 'secret!'
        done()



    it 'accepts configs parameter files that does not exist', (done) ->

      files = [
        bucketful: {
          bucket: 'file1'
          key: 'key!'
        }
      ]

      load = config.createLoader({ })

      async.map files, (file, callback) ->
        tmp.file propagate callback, (tmpFile) ->
          fs.writeFile tmpFile, JSON.stringify(file), propagate callback, ->
            callback(null, tmpFile)
      , (err, temps) ->
        throw err if err?
        load = config.createLoader({ })
        res = load({
          configs: 'file-does-not-exist;' + temps.join(';')
        })
        res.bucket.should.eql 'file1'
        res.key.should.eql 'key!'
        done()



    it 'load should throw an exception if any of the config files are not JSON', (done) ->

      files = [
        '{ "bucketful": { "bucket": "file1", "key": "key!" } }'
        'this is not json'
      ]

      load = config.createLoader({ })

      async.map files, (file, callback) ->
        tmp.file propagate callback, (tmpFile) ->
          fs.writeFile tmpFile, file, propagate callback, ->
            callback(null, tmpFile)
      , (err, temps) ->
        try
          res = load({
            configs: temps.join(';')
          })
        catch ex
          ex.message.should.eql 'Error parsing your JSON configuration file.'
          done()



    it 'can run "load" without arguments', (done) ->
      load = config.createLoader({ })
      load()
      done()
