path = require 'path'
nconf = require 'nconf'
deploy = require './deploy'

process.on 'uncaughtException', ->
  console.log("uncaught")
  console.log arguments

exports.deploy = (options) ->

  nconf.overrides(options).argv()
  nconf.file "config", "config.json"
  nconf.file "package", "package.json"
  nconf.env('__')
  nconf.file "user", path.join(process.env.HOME, ".bucketful")

  nconf.defaults bucketful:
    targetDir: path.join(process.cwd(), "public")
    websiteIndex: 'index.html'
    websiteError: 'index.html'

  s3bucket    = nconf.get 'bucketful:bucket'
  aws_key     = nconf.get 'bucketful:key'
  aws_secret  = nconf.get 'bucketful:secret'
  aws_user    = nconf.get 'bucketful:username'
  region      = nconf.get 'bucketful:region'
  siteIndex   = nconf.get 'bucketful:websiteIndex'
  siteError   = nconf.get 'bucketful:websiteError'
  loopiaOpts  = nconf.get 'loopia'
  targetDir   = path.resolve nconf.get 'bucketful:targetDir'

  deploy {
    s3bucket
    aws_key
    aws_secret
    aws_user
    region
    siteIndex
    siteError
    loopiaOpts
    targetDir
    verbose: true
  }, ->
    console.log("calling back", arguments)
