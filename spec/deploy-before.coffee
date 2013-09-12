fs = require 'fs'
tmp = require 'tmp'
_ = require 'underscore'

exports.before = (done) ->

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
