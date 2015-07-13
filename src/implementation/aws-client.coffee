Q = require 'q'
helpers = require './aws-sdk-helpers'

module.exports = (client) ->
  getBucketNames: Q.denodeify(helpers.getBucketNames.bind(null, client))
  createBucket: Q.denodeify(helpers.createBucket.bind(null, client))
  bucketToWebsite: Q.denodeify(helpers.bucketToWebsite.bind(null, client))
  giveEveryoneReadAccess: Q.denodeify(helpers.giveEveryoneReadAccess.bind(null, client))
  putFile: Q.denodeify(helpers.putFile.bind(null, client))
