_ = require 'underscore'

exports.getBucketNames = (s3, callback) ->
  s3.ListBuckets (err, data) ->
    if err
      callback(err)
    else if data.StatusCode != 200
      callback(new Error(data))
    else
      bucketData = data.Body.ListAllMyBucketsResult.Buckets.Bucket
      if Array.isArray(bucketData)
        callback(null, _(bucketData).pluck('Name'))
      else
        callback(null, [bucketData.Name])

exports.createBucket = (awsSdkS3, params, callback) ->
  awsSdkS3.client.createBucket { Bucket: params.name }, callback

exports.giveEveryoneReadAccess = (awsSdkS3, params, callback) ->
  awsSdkS3.client.getBucketAcl {
    Bucket: params.name
  }, (err, res) ->
    return callback(err) if err?

    pars = _.pick(res, 'Grants', 'Owner')

    pars.Grants.push({
      Permission: 'READ'
      Grantee: {
        URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
        Type: 'Group'
      }
    })

    awsSdkS3.client.putBucketAcl {
      Bucket: params.name
      AccessControlPolicy: pars
    }, callback


exports.bucketToWebsite = (awsSdkS3, params, callback) ->

  index = params.index ? 'index.html'
  error = params.error ? index

  awsSdkS3.client.putBucketWebsite {
    Bucket: params.name
    WebsiteConfiguration: {
      IndexDocument: {
        Suffix: index
      }
      ErrorDocument: {
        Key : error
      }
    }
  }, callback
