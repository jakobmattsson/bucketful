Q = require 'q'
helpers = require './aws-sdk-helpers'

module.exports = (client) ->
  getBucketNames: Q.nbind(helpers.getBucketNames.bind(null, client))
  createBucket: Q.nbind(helpers.createBucket.bind(null, client))
  bucketToWebsite: Q.nbind(helpers.bucketToWebsite.bind(null, client))
  giveEveryoneReadAccess: Q.nbind(helpers.giveEveryoneReadAccess.bind(null, client))
  putFile: Q.nbind(helpers.putFile.bind(null, client))
