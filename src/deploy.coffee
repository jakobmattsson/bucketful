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

  log = (args...) ->
    output.write(args.join(' ') + '\n') if output?

  targetDir = path.resolve(targetDir)

  log ""
  log "Loading settings"
  log "- bucket: #{s3bucket}"
  log "- aws key: #{aws_key.slice(0, 4)}#{_.times(aws_key.length-4, -> '*').join('')}"
  log "- aws secret: #{aws_secret.slice(0, 4)}#{_.times(aws_secret.length-4, -> '*').join('')}"
  log "- aws region: #{region}"
  log "- index: #{siteIndex}"
  log "- error: #{siteError}"
  log "- targetDir: #{targetDir}"

  powerfsIsFile = Q.nbind(powerfs.isFile, powerfs)

  aws = awsClient(createAwsClient({ region, key: aws_key, secret: aws_secret }))



  aws.getBucketNames().then (buckets) ->

    log ""
    if _(buckets).contains(s3bucket)
      log "Bucket found in the given aws account."
    else
      log "Bucket not found in the given account. Attempting to create it."

      aws.createBucket(s3bucket).then ->
        log "Bucket created. Configuring it as a website."
        aws.bucketToWebsite({ name: s3bucket, index: siteIndex, error: siteError })
      .then ->
        log "Setting read access for everyone."
        aws.giveEveryoneReadAccess(s3bucket)

  .then ->
    if dnsProvider?
      log()
      log "Configuring DNS at #{dnsProvider.namespace}."  # detta borde göras parallelt med uppladdningen
      cname = "#{s3bucket}.s3-website-#{region}.amazonaws.com"
      Q.nfcall(dnsProvider.setCNAME, s3bucket, cname)

  .then ->

    log()
    log "Uploading:"

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
    if dnsProvider?
      log "DNS configured to (eventually) make it available at: http://#{s3bucket}"
    else
      log "No DNS configured."

  .nodeify(callback)
