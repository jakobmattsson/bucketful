path = require 'path'
fs = require 'fs'
_ = require 'underscore'
optimist = require 'optimist'
nconf = require 'nconf'
optionsCfg = require './options'

exports.createLoader = ({ loadPlugin, userConfigPath }) ->

  (options) ->

    argnames = _.pluck(optionsCfg, 'name')
    shortNames = _.pick(optimist.argv, argnames)

    nconf.overrides({ bucketful: _.extend({}, options || {}, shortNames) }).argv()

    configs = nconf.get('bucketful:configs') || 'package.json;config.json'

    configs.split(';').filter((x) -> x).forEach (file, i) ->
      nconf.file("file_#{i+1}", file)

    nconf.env('__')
    nconf.file("user", userConfigPath) if userConfigPath

    dns = nconf.get('bucketful:dns')

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
      source: nconf.get('bucketful:source')
      dns: dnsObject
    }
