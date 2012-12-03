_ = require 'underscore'

exports.getBucketNames = (s3, callback) ->
  s3.ListBuckets (err, data) ->
    if err
      callback(err)
    else if data.StatusCode != 200
      callback(new Error(data))
    else
      callback(null, _.pluck(data.Body.ListAllMyBucketsResult.Buckets.Bucket, 'Name'))

exports.createBucket = (s3, params, callback) ->
  name = params.name
  fullRightsUser = params.fullRightsUser

  s3.CreateBucket { BucketName: name, GrantFullControl: 'emailAddress=' + fullRightsUser, GrantRead: 'uri=http://acs.amazonaws.com/groups/global/AllUsers' }, (err) ->
    callback(err?.Body?.Error?.Message || err)

exports.bucketToWebsite = (s3, params, callback) ->
  name = params.name
  index = params.index ? 'index.html'
  error = params.error ? index

  s3.PutBucketWebsite { BucketName: name, website: true, IndexDocument: index, ErrorDocument: error, key: error }, (err) ->
    callback(err?.Body?.Error?.Message || err)
