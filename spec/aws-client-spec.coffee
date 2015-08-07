should = require 'should'
AWS = require 'aws-sdk'

describe 'aws-client', ->

  it 'runs using the expected interface', ->
    AWS.config.update({
      region: "eu-west-1"
      accessKeyId: "key"
      secretAccessKey: "secret"
    })
    should.exist new AWS.S3().client
