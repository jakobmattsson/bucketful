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
