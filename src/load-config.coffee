path = require 'path'
nconf = require 'nconf'

exports.createLoader = ({ loadPlugin, userConfigPath }) ->
  (options) ->
    nconf.overrides(options).argv()
    nconf.file "config", "config.json"
    nconf.file "package", "package.json"
    nconf.env('__')
    nconf.file "user", userConfigPath
    nconf.defaults
      bucketful:
        websiteIndex: 'index.html'
        websiteError: 'index.html'

    dnsProvider = nconf.get('bucketful:dnsProvider')
    targetDir = nconf.get('bucketful:targetDir')

    if dnsProvider
      dnsReq = loadPlugin(dnsProvider)
      username = nconf.get("#{dnsReq.namespace}:username")
      password = nconf.get("#{dnsReq.namespace}:password")
      dnsObject = {
        setCNAME: dnsReq.create(username, password).setCNAME
        namespace: dnsReq.namespace
        username: username
        password: password
      }

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
