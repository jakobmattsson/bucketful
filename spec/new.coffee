should = require 'should'
jscov = require 'jscov'
deploy = require jscov.cover('..', 'src', 'deploy')

describe 'overall', ->

  mockAws = (region, key, secret) ->
    listBuckets: (opts, callback) ->
      console.log("calling LIST")
      callback(null, { Buckets: [] })
    createBucket: (opts, callback) ->
      console.log("calling CREATE")
      callback()
    putBucketWebsite: (opts, callback) ->
      console.log("calling PUTWEBSITE")
      callback()
    getBucketAcl: (opts, callback) ->
      console.log("calling GETACL")
      callback(null, {
        Grants: []
        Owner: {}
      })
    putBucketAcl: (opts, callback) ->
      console.log("calling PUTACL")
      callback()
    putObject: (opts, callback) ->
      console.log("calling PUTOBJ")
      callback()

  mockDns = {
    setCNAME: (bucket, cname, callback) ->
      console.log("sat cname", arguments)
      callback()
  }

  it 'runs', ->
    deploy
      s3bucket: 'mybucket.leanmachine.se'
      aws_key: 'awskey'
      aws_secret: 'awssecret'
      aws_user: 'myawsuser'
      region: 'eu-west-1'
      siteIndex: 'index.html'
      siteError: 'error.html'
      targetDir: 'spec'
      verbose: true
      dnsProvider: mockDns
      createAwsClient: mockAws
    , (err) ->
      should.not.exist err
      console.log "done..."
