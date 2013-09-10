path = require 'path'
fs = require 'fs'

# Silly hack to make this project testable without caching gotchas
loadnconf = ->
  if process.env.NODE_ENV != 'production'
    for key of require.cache
      delete require.cache[key]
  require 'nconf'

exports.createLoader = ({ loadPlugin, userConfigPath }) ->

  nconf = loadnconf()

  (options) ->
    nconf.overrides(options).argv()

    configs = nconf.get('bucketful:configs')

    (configs || '').split(';').filter((x) -> x).forEach (file, i) ->
      nconf.file("file_#{i+1}", file)

    nconf.env('__')
    nconf.file("user", userConfigPath) if userConfigPath
    nconf.defaults
      bucketful:
        index: 'index.html'

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

    resolvedSource = path.resolve(source) if source
    has404 = fs.existsSync(path.resolve(resolvedSource, '404.html')) if resolvedSource

    {
      bucket: nconf.get('bucketful:bucket')
      key: nconf.get('bucketful:key')
      secret: nconf.get('bucketful:secret')
      region: nconf.get('bucketful:region')
      index: nconf.get('bucketful:index')
      error: nconf.get('bucketful:error') || if has404 then '404.html' else nconf.get('bucketful:index')
      source: resolvedSource
      dns: dnsObject
    }
