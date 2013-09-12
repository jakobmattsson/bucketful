path = require 'path'
fs = require 'fs'
_ = require 'underscore'
should = require 'should'
jscov = require 'jscov'
deploy = require jscov.cover('..', 'src', 'implementation/deploy')
stringstream = require './util/stringstream'
tmp = require 'tmp'

describe 'deploy', ->

  override = (original, cb) ->
    (args...) -> cb.apply(this, [original].concat(args))

  beforeEach (done) ->

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

    tmp.dir (err, tmpDir) =>
      throw err if err?
      @uploadDir = tmpDir
      fs.writeFileSync(tmpDir + '/file.txt', 'hello')
      fs.writeFileSync(tmpDir + '/other.coffee', 'f = (args...) ->\n  args.slice(1)\n')
      done()



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
      source: @uploadDir
      output: output
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se found in the region eu-west-1.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        Uploading #{@uploadDir}:
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
      source: @uploadDir
      output: output
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se not found in the given account.
        Attempting to create it in the region eu-west-1.
        Bucket created.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        Uploading #{@uploadDir}:
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
      source: @uploadDir
      output: output
      createAwsClient: @mockAws
      dns: @mockDns
    , (err) =>
      throw err if err?
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se not found in the given account.
        Attempting to create it in the region eu-west-1.
        Bucket created.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        Configuring DNS at fakedns with username dnsu*** and password dnsp*******.

        Uploading #{@uploadDir}:
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
      source: @uploadDir
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'cannot list buckets'
      done()






  it 'yields an error if no bucket is given', (done) ->
    output = stringstream.createStream()
    deploy
      key: 'awskey'
      secret: 'awssecret'
      source: @uploadDir
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
      source: @uploadDir
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
      source: @uploadDir
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



  it 'yields an error if the region is invalid', (done) ->

    @listBuckets = (opts, callback) -> callback(new Error("failed"))
    output = stringstream.createStream()

    deploy
      key: 'awskey'
      secret: 'awssecret'
      source: @uploadDir
      bucket: 'somebucket'
      region: 'invalidregion'
      output: output
      createAwsClient: @mockAws
    , (err) =>
      err.message.should.eql 'failed'
      output.toString().should.eql '''

      Accessing aws account using key awsk** and secret awss*****.

      '''
      done()



  it 'defaults region to us-east-1 if no region is given', (done) ->
    output = stringstream.createStream()
    @expects = [
      method: 'createAws'
      args: [
        region: 'us-east-1'
        key: 'awskey'
        secret: 'awssecret'
      ]
    ]
    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      source: @uploadDir
      output: output
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      output.toString().should.include 'Attempting to create it in the region us-east-1.'
      done()



  it 'defaults index to index.html if undefined', (done) ->
    output = stringstream.createStream()

    @putBucketWebsite = override @putBucketWebsite, (base, opts, callback) =>
      suffix = opts?.WebsiteConfiguration?.IndexDocument?.Suffix || ''
      suffix.should.eql 'index.html'
      base(opts, callback)

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      source: @uploadDir
      output: output
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      done()



  it 'defaults error to 404.html, if the file exists in the source directory', (done) ->
    @putBucketWebsite = override @putBucketWebsite, (base, opts, callback) =>
      suffix = opts?.WebsiteConfiguration?.ErrorDocument?.Key || ''
      suffix.should.eql '404.html'
      base(opts, callback)

    tmp.dir (err, tmpdir) =>
      throw err if err?
      fs.writeFileSync(path.resolve(tmpdir, '404.html'), 'bla')
      deploy
        bucket: 'mybucket.leanmachine.se'
        key: 'awskey'
        secret: 'awssecret'
        source: tmpdir
        createAwsClient: @mockAws
      , (err) =>
        throw err if err?
        done()



  it 'defaults error to the same value as index, if no 404.html file exists in the source', (done) ->
    @putBucketWebsite = override @putBucketWebsite, (base, opts, callback) =>
      suffix = opts?.WebsiteConfiguration?.ErrorDocument?.Key || ''
      suffix.should.eql 'foobar.html'
      base(opts, callback)

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      index: 'foobar.html'
      secret: 'awssecret'
      source: @uploadDir
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      done()



  it 'defaults error to the same value as index, if no 404.html file exists in the source, when index is also undefined', (done) ->
    @putBucketWebsite = override @putBucketWebsite, (base, opts, callback) =>
      suffix = opts?.WebsiteConfiguration?.ErrorDocument?.Key || ''
      suffix.should.eql 'index.html'
      base(opts, callback)

    deploy
      bucket: 'mybucket.leanmachine.se'
      key: 'awskey'
      secret: 'awssecret'
      source: @uploadDir
      createAwsClient: @mockAws
    , (err) =>
      throw err if err?
      done()
