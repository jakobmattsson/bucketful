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
        index: 'index.html'
        error: 'index.html'

    dns = nconf.get('bucketful:dns')
    source = nconf.get('bucketful:source')

    if dns
      dnsReq = loadPlugin(dns)
      username = nconf.get("#{dnsReq.namespace}:username")
      password = nconf.get("#{dnsReq.namespace}:password")
      dnsObject = {
        setCNAME: dnsReq.create(username, password).setCNAME
        namespace: dnsReq.namespace
        username: username
        password: password
      }

    {
      bucket: nconf.get('bucketful:bucket')
      key: nconf.get('bucketful:key')
      secret: nconf.get('bucketful:secret')
      region: nconf.get('bucketful:region')
      index: nconf.get('bucketful:index')
      error: nconf.get('bucketful:error')
      source: path.resolve(source) if source?
      dns: dnsObject
    }
