path = require 'path'
_ = require 'underscore'
AWS = require 'aws-sdk'
deploy = require '../implementation/deploy'
config = require '../implementation/load-config'

exports.load = config.createLoader({
  loadPlugin: (plugin) -> require('../../../' + plugin)
  userConfigPath: path.resolve(process.env.HOME, ".bucketful")
})

exports.deploy = (options, callback) ->

  finalConf = _.extend({}, options, {
    createAwsClient: ({ region, key, secret }) ->
      AWS.config.update({
        region: region
        accessKeyId: key
        secretAccessKey: secret
      })
      new AWS.S3()
  })

  deploy(finalConf, callback)
