path = require 'path'
nconf = require 'nconf'

exports.load = (options) ->

  nconf.overrides(options).argv()
  nconf.file "config", "config.json"
  nconf.file "package", "package.json"
  nconf.env('__')
  nconf.file "user", path.resolve(process.env.HOME, ".bucketful")
  nconf.defaults
    bucketful:
      websiteIndex: 'index.html'
      websiteError: 'index.html'

  dnsProvider = nconf.get('bucketful:dnsProvider')

  if dnsProvider
    dnsReq = require('./bucketful-loopia') if dnsProvider == 'bucketful-loopia'
    #dnsReq = require('../../' + dnsProvider)
    username = nconf.get("#{dnqReq.namespace}:username")
    password = nconf.get("#{dnqReq.namespace}:password")
    dnsObject = dnsReq.create(username, password)

  targetDir = nconf.get('bucketful:targetDir')

  {
    s3bucket: nconf.get('bucketful:bucket')
    aws_key: nconf.get('bucketful:key')
    aws_secret: nconf.get('bucketful:secret')
    region: nconf.get('bucketful:region')
    siteIndex: nconf.get('bucketful:websiteIndex')
    siteError: nconf.get('bucketful:websiteError')
    targetDir: path.resolve(targetDir) if targetDir?
    dnsProvider: dnsObject
  }
