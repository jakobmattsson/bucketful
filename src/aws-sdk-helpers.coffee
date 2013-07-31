fs = require 'fs'
mime = require 'mime'
_ = require 'underscore'

exports.putFile = (s3client, {filename, target, bucket}, callback) ->
  s3client.putObject
    ACL: 'public-read'
    Bucket: bucket
    ContentType: mime.lookup(filename)
    Key: target.replace(/^\/*/g, '')
    Body: fs.readFileSync(filename)
  , callback


exports.getBucketNames = (s3client, callback) ->
  s3client.listBuckets { }, (err, { Buckets }) ->
    return callback(err) if err?
    bucketNames = Buckets.map (x) -> x.Name
    callback(null, bucketNames)

exports.createBucket = (s3client, {name}, callback) ->
  s3client.createBucket { Bucket: name }, callback

exports.giveEveryoneReadAccess = (s3client, {name}, callback) ->

  s3client.getBucketAcl
    Bucket: name
  , (err, res) ->
    return callback(err) if err?

    pars = _.pick(res, 'Grants', 'Owner')

    pars.Grants.push
      Permission: 'READ'
      Grantee:
        URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
        Type: 'Group'

    awsSdkS3.client.putBucketAcl
      Bucket: name
      AccessControlPolicy: pars
    , callback


exports.bucketToWebsite = (s3client, {index, error, name}, callback) ->

  index ?= 'index.html'
  error ?= index

  s3client.putBucketWebsite
    Bucket: name
    WebsiteConfiguration:
      IndexDocument:
        Suffix: index
      ErrorDocument:
        Key : error
  , callback
