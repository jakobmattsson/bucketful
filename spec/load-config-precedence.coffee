async = require 'async'
fs = require 'fs'
path = require 'path'
should = require 'should'
tmp = require 'tmp'
jscov = require 'jscov'
_ = require 'underscore'
config = require jscov.cover('..', 'src', 'load-config')

propagate = (onErr, onSucc) -> (err, rest...) -> if err? then onErr(err) else onSucc(rest...)

describe 'load-config', ->

  describe 'load', ->

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
          res = load({ bucketful: bucket: 'function.bucket' })
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
          bucketful: {
            configs: temps.join(';')
          }
        })
        res.bucket.should.eql 'file1'
        res.key.should.eql 'key!'
        res.secret.should.eql 'secret!'
        done()
