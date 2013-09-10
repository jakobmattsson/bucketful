path = require 'path'
fs = require 'fs'
_ = require 'underscore'
should = require 'should'
jscov = require 'jscov'
deploy = require jscov.cover('..', 'src', 'deploy')
stringstream = require './util/stringstream'

describe 'deploy', ->

  override = (original, cb) ->
    (args...) -> cb.apply(this, [original].concat(args))

  beforeEach ->

    popOne = (method, argumentsObject) =>
      syncMethods = ['createAws']
      args = _.toArray(argumentsObject)
      next = @expects?.shift()

      if next
        method.should.eql next.method

        if method in syncMethods
          args.should.eql next.args
        else
          args.slice(0, -1).should.eql next.args
          args.slice(-1)[0].should.be.a('function')

    @listBuckets = (opts, callback) ->
      popOne('listBuckets', arguments)
      callback(null, { Buckets: [] })

    @createBucket = (opts, callback) ->
      popOne('createBucket', arguments)
      callback()

    @putBucketWebsite = (opts, callback) ->
      popOne('putBucketWebsite', arguments)
      callback()

    @getBucketAcl = (opts, callback) ->
      popOne('getBucketAcl', arguments)
      callback(null, {
        Grants: []
        Owner: {}
      })

    @putBucketAcl = (opts, callback) ->
      popOne('putBucketAcl', arguments)
      callback()

    @putObject = (opts, callback) ->
      popOne('putObject', arguments)
      callback()

    @mockAws = () =>
      popOne('createAws', arguments)
      { @listBuckets, @createBucket, @putBucketWebsite, @getBucketAcl, @putBucketAcl, @putObject }

    @mockDns = {
      username: 'dnsuser'
      password: 'dnspassword'
      namespace: 'fakedns'
      setCNAME: (bucket, cname, callback) ->
        popOne('setCNAME', arguments)
        callback()
    }





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
        Body: fs.readFileSync('./spec/data/file.txt')
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'application/octet-stream'
        Key: 'other.coffee'
        Body: fs.readFileSync('./spec/data/other.coffee')
      ]
    ]

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: 'spec/data'
      dns: @mockDns
      createAwsClient: @mockAws
    , (err) =>
      should.not.exist err
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
        Body: fs.readFileSync('./spec/data/file.txt')
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'application/octet-stream'
        Key: 'other.coffee'
        Body: fs.readFileSync('./spec/data/other.coffee')
      ]
    ]

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: 'spec/data'
      createAwsClient: @mockAws
    , (err) =>
      should.not.exist err
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
        Body: fs.readFileSync('./spec/data/file.txt')
      ]
    ,
      method: 'putObject'
      args: [
        ACL: 'public-read'
        Bucket: 'mybucket.leanmachine.se'
        ContentType: 'application/octet-stream'
        Key: 'other.coffee'
        Body: fs.readFileSync('./spec/data/other.coffee')
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
      source: 'spec/data'
      createAwsClient: @mockAws
    , (err) =>
      should.not.exist err
      @expects.should.have.length 0
      done()





  it 'prints the right stuff when the bucket already exists', (done) ->

    output = stringstream.createStream()

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
      source: 'spec/data'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      should.not.exist err
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se found in the region eu-west-1.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        Uploading #{path.resolve(__dirname, 'data')}:
        [1/2] file.txt
        [2/2] other.coffee

        Site now available on: http://mybucket.leanmachine.se.s3-website-eu-west-1.amazonaws.com
        No DNS configured.

      """
      done()





  it 'prints the right stuff when the bucket must be created', (done) ->

    output = stringstream.createStream()

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: 'spec/data'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      should.not.exist err
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se not found in the given account.
        Attempting to create it in the region eu-west-1.
        Bucket created.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        Uploading #{path.resolve(__dirname, 'data')}:
        [1/2] file.txt
        [2/2] other.coffee

        Site now available on: http://mybucket.leanmachine.se.s3-website-eu-west-1.amazonaws.com
        No DNS configured.

      """
      done()





  it 'prints the right stuff when a dns provider is given', (done) ->

    output = stringstream.createStream()

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      region: 'eu-west-1'
      index: 'index.html'
      error: 'error.html'
      source: 'spec/data'
      output: output
      createAwsClient: @mockAws
      dns: @mockDns
    , (err) =>
      should.not.exist err
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se not found in the given account.
        Attempting to create it in the region eu-west-1.
        Bucket created.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        Configuring DNS at fakedns with username dnsu*** and password dnsp*******.

        Uploading #{path.resolve(__dirname, 'data')}:
        [1/2] file.txt
        [2/2] other.coffee

        Site now available on: http://mybucket.leanmachine.se.s3-website-eu-west-1.amazonaws.com
        DNS configured to also make it available at: http://mybucket.leanmachine.se

      """
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
      source: 'spec/data'
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'cannot list buckets'
      done()






  it 'yields an error if no bucket is given', (done) ->
    output = stringstream.createStream()
    deploy
      key: 'awskey'
      secret: 'awssecret'
      source: 'spec/data'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'Must supply a bucket'
      output.toString().should.eql ''
      done()

  it 'yields an error if no key is given', (done) ->
    output = stringstream.createStream()
    deploy
      bucket: 'mybucket.leanmachine.se'
      secret: 'awssecret'
      source: 'spec/data'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'Must supply an AWS key'
      output.toString().should.eql ''
      done()

  it 'yields an error if no secret is given', (done) ->
    output = stringstream.createStream()
    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      source: 'spec/data'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'Must supply an AWS secret token'
      output.toString().should.eql ''
      done()

  it 'yields an error if no source is given', (done) ->
    output = stringstream.createStream()
    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'Must supply a source directory'
      output.toString().should.eql ''
      done()
