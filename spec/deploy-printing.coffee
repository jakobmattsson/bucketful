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



  it 'prints the right stuff when the bucket already exists', (done) ->

    output = createStream()

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

    output = createStream()

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
    output = createStream()
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




  it 'prints the right stuff when a dns provider is given', (done) ->
    output = createStream()
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
      dns: {
        namespace: 'fakedns'
        setCNAME: (bucket, cname, callback) ->
          popOne('setCNAME', arguments)
          callback()
      }
    , (err) =>
      throw err if err?
      output.toString().should.eql """


        Accessing aws account using key awsk** and secret awss*****.
        Bucket mybucket.leanmachine.se not found in the given account.
        Attempting to create it in the region eu-west-1.
        Bucket created.
        Setting website config using index.html as index and error.html as error.
        Setting read access for everyone.

        WARNING: Provided domain registrar, but not username/password.

        Uploading #{@uploadDir}:
        [1/2] file.txt
        [2/2] other.coffee

        Site now available on: http://mybucket.leanmachine.se.s3-website-eu-west-1.amazonaws.com
        No DNS configured.

      """
      done()
