should = require 'should'
jscov = require 'jscov'
help = require jscov.cover('..', 'src', 'help')

describe 'help', ->

  describe 'getHelpText', ->

    it 'produces the expected help text', (done) ->

      help.getHelpText().should.eql '''
        Deploys websites to Amazon S3

        Options:
          --source       Directory to use as starting point for the upload
          --bucket       S3 bucket used as target for the upload
          --key          AWS access key
          --secret       AWS access secret
          --region       AWS region to create the bucket in (defaults to 'us-east-1')
          --index        File to use as index page (defaults to 'index.html')
          --error        File to use as error page
          --dns          The name of a bucketful plugin for configuring a CNAME
          --configs      Configuration files (defaults to 'package.json;config.json')
          --version, -v  Print the current version number
          --help, -h     Show this help message

      '''
      done()
