fs = require 'fs'
mime = require 'mime'
path = require 'path'
_ = require 'underscore'
equal = require 'deep-equal'

propagate = (onErr, onSucc) -> (err, rest...) -> if err? then onErr(err) else onSucc(rest...)

exports.putFile = (s3client, {filename, target, bucket, defaultContentType}, callback) ->
  s3client.putObject
    ACL: 'public-read'
    Bucket: bucket
    ContentType: if path.extname(filename) == '' then defaultContentType else mime.lookup(filename)
    Key: target.replace(/^\/*/g, '')
    Body: fs.readFileSync(filename)
  , callback

exports.getBucketNames = (s3client, callback) ->
  s3client.listBuckets { }, propagate callback, ({ Buckets }) ->
    callback(null, _.pluck(Buckets, 'Name'))

exports.createBucket = (s3client, name, callback) ->
  s3client.createBucket { Bucket: name }, callback

exports.giveEveryoneReadAccess = (s3client, name, callback) ->

  s3client.getBucketAcl
    Bucket: name
  , propagate callback, (res) ->
    pars = _.pick(res, 'Grants', 'Owner')
    found = []

    pars.Grants.push
      Permission: 'READ'
      Grantee:
        URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
        Type: 'Group'

    pars.Grants = _.filter(pars.Grants, (grant) ->
      unless _.some(found, (foundGrant) -> equal(grant, foundGrant))
        return found.push grant
    )

    s3client.putBucketAcl
      Bucket: name
      AccessControlPolicy: pars
    , callback

exports.bucketToWebsite = (s3client, {index, error, name}, callback) ->
  s3client.putBucketWebsite
    Bucket: name
    WebsiteConfiguration:
      IndexDocument:
        Suffix: index
      ErrorDocument:
        Key: error
  , callback
