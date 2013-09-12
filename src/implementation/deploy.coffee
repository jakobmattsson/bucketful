Q = require 'q'
_ = require 'underscore'
path = require 'path'
wrench = require 'wrench'
powerfs = require 'powerfs'

awsClient = require './aws-client'




qfilter = (list, filterFunc) ->
  ps = list.map(filterFunc)
  Q.all(ps).then (mask) ->
    list.filter (x, i) -> mask[i]




maskString = (str) -> str.slice(0, 4) + _.times(str.length-4, -> '*').join('')

module.exports = ({
  output
  createAwsClient
  dns
  bucket
  key
  secret
  region
  index
  error
  source
}, callback = ->) ->

  return callback(new Error("Must supply a bucket")) if !bucket?
  return callback(new Error("Must supply an AWS key")) if !key?
  return callback(new Error("Must supply an AWS secret token")) if !secret?
  return callback(new Error("Must supply a source directory")) if !source?

  log = (args...) -> output.write(args.join(' ') + '\n') if output?

  source = path.resolve(source)
  region ?= 'us-east-1'
  index ?= 'index.html'

  powerfsIsFile = Q.nbind(powerfs.isFile, powerfs)
  powerfsFileExits = Q.nbind(((p, callback) -> powerfs.fileExists(p, (r) -> callback(null, r))), powerfs)

  aws = awsClient(createAwsClient({ region, key: key, secret: secret }))

  log ""
  log "Accessing aws account using key #{maskString(key)} and secret #{maskString(secret)}."

  powerfsFileExits(path.resolve(source, '404.html')).then (has404) ->
    return if error
    if has404
      error = '404.html'
    else
      error = index
  .then ->
    aws.getBucketNames()
  .then (buckets) ->

    if _(buckets).contains(bucket)
      log "Bucket #{bucket} found in the region #{region}."
    else
      log "Bucket #{bucket} not found in the given account."
      log "Attempting to create it in the region #{region}."

      aws.createBucket(bucket).then ->
        log "Bucket created."
  .then ->
    log "Setting website config using #{index} as index and #{error} as error."
    aws.bucketToWebsite({ name: bucket, index: index, error: error })
  .then ->
    log "Setting read access for everyone."
    aws.giveEveryoneReadAccess(bucket)
  .then ->
    if dns?
      if dns.username? && dns.password?
        log()
        log "Configuring DNS at #{dns.namespace} with username #{maskString(dns.username)} and password #{maskString(dns.password)}."
        Q.nfcall(dns.setCNAME, bucket, "#{bucket}.s3-website-#{region}.amazonaws.com")
      else
        log()
        log "WARNING: Provided domain registrar, but not username/password."

  .then ->
    wrench.readdirSyncRecursive(source).map (x) -> { fullpath: path.join(source, x), name: x }

  .then (files) ->
    qfilter files, (file) -> powerfsIsFile(file.fullpath)

  .then (files) ->
    log()
    log "Uploading #{source}:"
    counter = 0

    Q.all files.map (file, i) ->
      aws.putFile({
        filename: file.fullpath
        target: file.name
        bucket: bucket
      }).then ->
        counter++
        padding = _.times(10, -> " ").join('')
        counterStr = (padding + counter).slice(-files.length.toString().length)
        log "[#{counterStr}/#{files.length}] #{file.name}"

  .then ->
    log ""
    log "Site now available on: http://#{bucket}.s3-website-#{region}.amazonaws.com"
    if dns? && dns.username? && dns.password?
      log "DNS configured to also make it available at: http://#{bucket}"
    else
      log "No DNS configured."

  .nodeify(callback)
