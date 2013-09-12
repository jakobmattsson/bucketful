path = require 'path'
fs = require 'fs'
_ = require 'underscore'
should = require 'should'
jscov = require 'jscov'
tmp = require 'tmp'

{createStream, override} = require './util/stringstream'
bfr = require './deploy-before'

deploy = require jscov.cover('..', 'src', 'implementation/deploy')

describe 'deploy', ->

  beforeEach(bfr.before)

  it 'runs properly given a sane set of arguments', (done) ->

    @expects = [
      method: 'createAws'
      args: [
        region: 'eu-west-1'
        key: 'awskey'
        secret: 'awssecret'
      ]
    ,
      method: 'listBuckets'
      args: [{}]
    ,
      method: 'createBucket'
      args: [
        Bucket: 'mybucket.leanmachine.se'
      ]
    ,
      method: 'putBucketWebsite'
      args: [
        Bucket: 'mybucket.leanmachine.se'
        WebsiteConfiguration:
          IndexDocument:
            Suffix: 'index.html'
          ErrorDocument:
            Key : 'error.html'
      ]
    ,
      method: 'getBucketAcl'
      args: [
        Bucket: 'mybucket.leanmachine.se'
      ]
    ,
      method: 'putBucketAcl'
      args: [
        Bucket: 'mybucket.leanmachine.se'
        AccessControlPolicy:
          Owner: {}
          Grants: [
            Permission: 'READ'
            Grantee:
              URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
              Type: 'Group'
          ]
      ]
    ,
      method: 'setCNAME'
      args: ['mybucket.leanmachine.se', 'mybucket.leanmachine.se.s3-website-eu-west-1.amazonaws.com']
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'text/plain'
        Key: 'file.txt'
        Body: fs.readFileSync(path.resolve(@uploadDir, 'file.txt'))
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'application/octet-stream'
        Key: 'other.coffee'
        Body: fs.readFileSync(path.resolve(@uploadDir, 'other.coffee'))
      ]
    ]

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: @uploadDir
      dns: @mockDns
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      @expects.should.have.length 0
      done()





  it 'simply ignores setting the cname if no provider is given', (done) ->

    @expects = [
      method: 'createAws'
      args: [
        region: 'eu-west-1'
        key: 'awskey'
        secret: 'awssecret'
      ]
    ,
      method: 'listBuckets'
      args: [{}]
    ,
      method: 'createBucket'
      args: [
        Bucket: 'mybucket.leanmachine.se'
      ]
    ,
      method: 'putBucketWebsite'
      args: [
        Bucket: 'mybucket.leanmachine.se'
        WebsiteConfiguration:
          IndexDocument:
            Suffix: 'index.html'
          ErrorDocument:
            Key : 'error.html'
      ]
    ,
      method: 'getBucketAcl'
      args: [
        Bucket: 'mybucket.leanmachine.se'
      ]
    ,
      method: 'putBucketAcl'
      args: [
        Bucket: 'mybucket.leanmachine.se'
        AccessControlPolicy:
          Owner: {}
          Grants: [
            Permission: 'READ'
            Grantee:
              URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
              Type: 'Group'
          ]
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'text/plain'
        Key: 'file.txt'
        Body: fs.readFileSync(path.resolve(@uploadDir, 'file.txt'))
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'application/octet-stream'
        Key: 'other.coffee'
        Body: fs.readFileSync(path.resolve(@uploadDir, 'other.coffee'))
      ]
    ]

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: @uploadDir
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      @expects.should.have.length 0
      done()




  it 'does not attempt to create a new bucket if it already exists', (done) ->

    @expects = [
      method: 'createAws'
      args: [
        region: 'eu-west-1'
        key: 'awskey'
        secret: 'awssecret'
      ]
    ,
      method: 'listBuckets'
      args: [{}]
    ,
      method: 'putBucketWebsite'
      args: [
        Bucket: 'mybucket.leanmachine.se'
        WebsiteConfiguration:
          IndexDocument:
            Suffix: 'index.html'
          ErrorDocument:
            Key : 'error.html'
      ]
    ,
      method: 'getBucketAcl'
      args: [
        Bucket: 'mybucket.leanmachine.se'
      ]
    ,
      method: 'putBucketAcl'
      args: [
        Bucket: 'mybucket.leanmachine.se'
        AccessControlPolicy:
          Owner: {}
          Grants: [
            Permission: 'READ'
            Grantee:
              URI: 'http://acs.amazonaws.com/groups/global/AllUsers'
              Type: 'Group'
          ]
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'text/plain'
        Key: 'file.txt'
        Body: fs.readFileSync(path.resolve(@uploadDir, 'file.txt'))
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'application/octet-stream'
        Key: 'other.coffee'
        Body: fs.readFileSync(path.resolve(@uploadDir, 'other.coffee'))
      ]
    ]

    @listBuckets = override @listBuckets, (base, opts, callback) =>
      base opts, ->
        callback(null, { Buckets: [{ Name: 'mybucket.leanmachine.se' }] })

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: @uploadDir
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      @expects.should.have.length 0
      done()








  it 'propagates errors properly', (done) ->

    @listBuckets = (opts, callback) -> callback(new Error("cannot list buckets"))

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: @uploadDir
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'cannot list buckets'
      done()



  it 'can be executed without a callback', (done) ->

    deploy
      createAwsClient: @mockAws

    setTimeout ->
      done()
    , 10
