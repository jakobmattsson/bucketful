Q = require 'q'
helpers = require './aws-sdk-helpers'

module.exports = (awsSdkS3) ->
  getBucketNames: Q.nbind(helpers.getBucketNames.bind(null, awsSdkS3))
  createBucket: Q.nbind(helpers.createBucket.bind(null, awsSdkS3))
  bucketToWebsite: Q.nbind(helpers.bucketToWebsite.bind(null, awsSdkS3))
  giveEveryoneReadAccess: Q.nbind(helpers.giveEveryoneReadAccess.bind(null, awsSdkS3))
  putFile: Q.nbind(helpers.putFile.bind(null, awsSdkS3))
