Q = require 'q'
AWS = require 'aws-sdk'
helpers = require './aws-sdk-helpers'

module.exports = ({ region, aws_key, aws_secret}) ->
  AWS.config.update
    region: region
    accessKeyId: aws_key
    secretAccessKey: aws_secret

  awsSdkS3 = new AWS.S3()

  getBucketNames: Q.nbind(helpers.getBucketNames.bind(null, awsSdkS3.client))
  createBucket: Q.nbind(helpers.createBucket.bind(null, awsSdkS3.client))
  bucketToWebsite: Q.nbind(helpers.bucketToWebsite.bind(null, awsSdkS3.client))
  giveEveryoneReadAccess: Q.nbind(helpers.giveEveryoneReadAccess.bind(null, awsSdkS3.client))
  putFile: Q.nbind(helpers.putFile.bind(null, awsSdkS3.client))
