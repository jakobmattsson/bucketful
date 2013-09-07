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

  callbackOnce = _.once(callback)

  {
    output
    createAwsClient
    dnsProvider
    s3bucket
    aws_key
    aws_secret
    aws_user
    region
    siteIndex
    siteError
    targetDir
  } = options

  log = (args...) ->
    str = args.join(' ')
    output.write(str + '\n') if output?

  log ""
  log "STEP 1 - Loading settings??"
  log "========================="
  log "Loaded the following options", options
  log "Resolved targetDir", targetDir

  powerfsIsFile = Q.nbind(powerfs.isFile, powerfs)

  aws = awsClient(createAwsClient({ region, key: aws_key, secret: aws_secret }))


  log ""
  log "STEP 2 - Locating bucket"
  log "========================"

  aws.getBucketNames().then (buckets) ->

    if _(buckets).contains(s3bucket)
      log "Success: Bucket found in the given account"
    else
      log "Warning: Bucket not found in the given account. Attempting to create it."

      aws.createBucket({ name: s3bucket, fullRightsUser: aws_user, key: aws_key, secret: aws_secret }).then ->
        log "Bucket created. Configuring it as a website."
        aws.bucketToWebsite({ name: s3bucket, index: siteIndex, error: siteError })
      .then ->
        log "Setting READ access for everyone."
        aws.giveEveryoneReadAccess({ name: s3bucket })
      .then ->
        log "Success: Bucket created!"

  .then ->
    if dnsProvider?
      log "setting up cname for bucket"
      cname = "#{s3bucket}.s3-website-#{region}.amazonaws.com"
      Q.nfcall(dnsProvider.setCNAME, s3bucket, cname)

  .then ->

    log()
    log "STEP #3 - Upload"
    log "================"

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
    log "done"
    log ""
    log "STEP 4 - Keeping you up to speed"
    log "================================"
    log "Site now available on: http://#{s3bucket}.s3-website-#{region}.amazonaws.com"
    log "If your DNS has been configured correctly, it can also be found here: http://#{s3bucket}"
    log ""
    log "kthxbai"


  .fail (err) ->
    log ""
    log "FAILED MISERABLY!"
    log err
    callbackOnce(err)

  .then ->
    callbackOnce()

  .done()
