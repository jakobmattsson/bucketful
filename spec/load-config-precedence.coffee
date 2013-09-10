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
