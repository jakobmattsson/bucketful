should = require 'should'
AWS = require 'aws-sdk'

describe 'aws-client', ->

  it 'runs using the expected interface', ->
    AWS.config.update({
      region: "us-east-1"
      accessKeyId: "key"
      secretAccessKey: "secret"
    })
    should.exist new AWS.S3().getObject
