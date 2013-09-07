_ = require 'underscore'
AWS = require 'aws-sdk'
deploy = require './deploy'
config = require './load-config'

exports.load = config.load

exports.deploy = (options, callback) ->

  finalConf = _.extend({}, options, {
    createAwsClient: (region, key, secret) ->
      AWS.config.update({
        region: region
        accessKeyId: key
        secretAccessKey: secret
      })
      new AWS.S3().client
  })

  deploy(finalConf, callback)
