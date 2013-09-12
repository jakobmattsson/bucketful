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

  it 'yields an error if no bucket is given', (done) ->
    output = createStream()
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
    output = createStream()
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
    output = createStream()
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
    output = createStream()
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
    output = createStream()

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
    output = createStream()
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
    output = createStream()

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
