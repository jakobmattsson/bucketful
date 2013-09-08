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

module.exports = (options, callback = ->) ->

  {
    output
    createAwsClient
    dnsProvider
    s3bucket
    aws_key
    aws_secret
    region
    siteIndex
    siteError
    targetDir
  } = options

  log = (args...) -> output.write(args.join(' ') + '\n') if output?

  targetDir = path.resolve(targetDir)

  powerfsIsFile = Q.nbind(powerfs.isFile, powerfs)

  aws = awsClient(createAwsClient({ region, key: aws_key, secret: aws_secret }))

  maskedKey = maskString(aws_key)
  maskedSecret = maskString(aws_secret)

  log ""
  log "Accessing aws account using key #{maskedKey} and secret #{maskedSecret}."

  aws.getBucketNames().then (buckets) ->

    if _(buckets).contains(s3bucket)
      log "Bucket #{s3bucket} found in the region #{region}."
    else
      log "Bucket #{s3bucket } not found in the given account."
      log "Attempting to create it in the region #{region}."

      aws.createBucket(s3bucket).then ->
        log "Bucket created."
        log "Setting website config using #{siteIndex} as index and #{siteError} as error."
        aws.bucketToWebsite({ name: s3bucket, index: siteIndex, error: siteError })
      .then ->
        log "Setting read access for everyone."
        aws.giveEveryoneReadAccess(s3bucket)

  .then ->
    if dnsProvider?
      
      if dnsProvider.username? && dnsProvider.password?
        log()
        log "Configuring DNS at #{dnsProvider.namespace} with username #{maskString(dnsProvider.username)} and password #{maskString(dnsProvider.password)}."
        cname = "#{s3bucket}.s3-website-#{region}.amazonaws.com"
        Q.nfcall(dnsProvider.setCNAME, s3bucket, cname)
      else
        log()
        log "WARNING: Provided domain registrar, but not username/password"

  .then ->

    log()
    log "Uploading #{targetDir}:"

    wrench.readdirSyncRecursive(targetDir).map (x) -> { fullpath: path.join(targetDir, x), name: x }

  .then (files) ->
    qfilter files, (file) -> powerfsIsFile(file.fullpath)

  # Upload the remaining files
  .then (files) ->
    counter = 0

    Q.all files.map (file, i) ->
      aws.putFile({
        filename: file.fullpath
        target: file.name
        bucket: s3bucket
      }).then ->
        counter++
        padding = _.times(10, -> " ").join('')
        counterStr = (padding + counter).slice(-files.length.toString().length)
        log "[#{counterStr}/#{files.length}] #{file.name}"

  .then ->
    log ""
    log "Site now available on: http://#{s3bucket}.s3-website-#{region}.amazonaws.com"
    if dnsProvider?.username? && dnsProvider?.password?
      log "DNS configured to also make it available at: http://#{s3bucket}"
    else
      log "No DNS configured."

  .nodeify(callback)
