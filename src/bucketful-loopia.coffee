loopia = require 'loopia-api'
loopiaTools = require './loopia'

exports.namespace = 'loopia'

exports.create = (username, password) ->
  loopiaClient = loopia.createClient(username, password)

  setCNAME: (bucket, cname, callback) ->
    loopiaTools.putSubdomainCNAME(loopiaClient, bucket, cname, callback)
