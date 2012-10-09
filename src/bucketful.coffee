Q = require 'q'
_ = require 'underscore'
_s = require 'underscore.string'
opra = require 'opra'
knox = require 'knox'
path = require 'path'
nconf = require 'nconf'
wrench = require 'wrench'
powerfs = require 'powerfs'

qfilter = (list, callback) ->
  ps = list.map callback
  Q.all(ps).then (mask) ->
    list.filter (x, i) -> mask[i]

exports.deploy = (options) ->

  nconf.overrides(options).argv()
  nconf.file "config", "config.json"
  nconf.file "package", "package.json"
  nconf.file "user", path.join(process.env.HOME, ".bucketful")

  nconf.env().defaults bucketful:
    html: ["index.html"]
    targetDir: path.join(process.cwd(), "public")
    include: []
    exclude: []
    opra:
      inline: true

  s3bucket    = nconf.get 'bucketful:bucket'
  aws_key     = nconf.get 'bucketful:key'
  aws_secret  = nconf.get 'bucketful:secret'
  excludes    = nconf.get 'bucketful:exclude'
  includes    = nconf.get 'bucketful:include'
  html        = nconf.get 'bucketful:html'
  opraOptions = nconf.get 'bucketful:opra'
  targetDir   = path.resolve nconf.get 'bucketful:targetDir'

  console.log "Resolved targetDir", targetDir
  console.log "Loaded the following options", nconf.get 'bucketful'

  client = knox.createClient
    key: aws_key
    secret: aws_secret
    bucket: s3bucket
    endpoint: s3bucket + ".s3-external-3.amazonaws.com"

  opraBuild = Q.nbind(opra.build, opra)
  powerfsWriteFile = Q.nbind(powerfs.writeFile, powerfs)
  powerfsIsFile = Q.nbind(powerfs.isFile, powerfs)
  clientPutFile = Q.nbind(client.putFile, client)



  ## This functions handles the uploading of all static files (those not compiled by opra)
  uploadTrack = ->

    # Get the list of files as described by the "includes" argument
    Q.resolve().then ->
      files = []
      if includes.length > 0
        includes.forEach (file) ->
          fullpath = path.join(targetDir, file)
          if powerfs.isDirectorySync(fullpath)
            files = files.concat wrench.readdirSyncRecursive(fullpath).map (f) -> path.join file, f
          else
            files.push file

      else
        files = wrench.readdirSyncRecursive(targetDir)
      files

    # Exclude files based on the "excludes" argument
    .then (files) ->
      files.filter (file) ->
        excludes.every (x) ->
          file != x and !_s.startsWith(file, x + "/")

    # Exclude directories
    .then (files) ->
      qfilter files, (file) -> powerfsIsFile(path.join(targetDir, file))

    # Upload the remaining files
    .then (files) ->
      console.log "Uploading #{files.length} static files..."
      counter = 0

      Q.all files.map (file, i) ->
        clientPutFile(path.join(targetDir, file), "/" + file).then ->
          counter++
          console.log "static [#{counter}/#{files.length}] #{file}"



  ## This functions manages the files that should be compiled by opra
  compileTrack = ->
    uploadCount = 0
    console.log "Compiling #{html.length} opra files..."

    # for each html file
    Q.all html.map (file) ->

      # run the opra builder
      opraBuild("public/#{file}", opraOptions)

      # write the file to disk
      .then (data) ->
        powerfsWriteFile "tmp/" + file, data, "utf8"

      # upload the file
      .then ->
        clientPutFile "tmp/" + file, "/" + file

      # print the completion message
      .then ->
        uploadCount++
        console.log "opra [#{uploadCount}/#{html.length}] Upload of #{file} completed"

    # when all html files have been processed
    .then ->
      console.log "done"



  # Run the two tracks at the same time
  Q.all([uploadTrack(), compileTrack()]).end()
