Q = require 'q'
_ = require 'underscore'
_s = require 'underscore.string'
opra = require 'opra'
knox = require 'knox'
path = require 'path'
nconf = require 'nconf'
wrench = require 'wrench'
powerfs = require 'powerfs'

process.on 'uncaughtException', ->
  console.log arguments

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

  console.log("Files to compile using opra:")
  html.forEach (y) ->
    console.log("*", y)

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

      files = files.map (x) -> { fullpath: path.join(targetDir, x), name: x }
      files

    # Exclude files based on the "excludes" argument
    .then (files) ->
      files.filter (file) ->
        excludes.every (x) ->
          file.name != x && !_s.startsWith(file.name, x + "/")

    # Exclude directories
    .then (files) ->
      qfilter files, (file) -> powerfsIsFile file.fullpath

    # Exclude hidden files
    .then (files) ->
      files.filter (file) -> file.name.split('/').every (part) -> part[0] != '.'

    # Exclude opra-processed files
    .then (files) ->
      files.filter (file) -> !_(html).contains(file.name)

    # Upload the remaining files
    .then (files) ->
      console.log "Uploading #{files.length} static files..."
      counter = 0

      Q.all files.map (file, i) ->
        clientPutFile(file.fullpath, "/" + file.name).then ->
          counter++
          console.log "static [#{counter}/#{files.length}] #{file.name}"



  ## This functions manages the files that should be compiled by opra
  uploadOpraTrack = ->
    uploadCount = 0
    console.log "Uploading #{html.length} opra files..."

    # for each html file
    Q.all html.map (file) ->

      clientPutFile("tmp/" + file, "/" + file)

      # print the completion message
      .then ->
        uploadCount++
        console.log "opra [#{uploadCount}/#{html.length}] Upload of #{file} completed"



  ## This functions manages the files that should be compiled by opra
  compileTrack = ->
    compileCount = 0
    console.log "Compiling #{html.length} opra files..."

    # for each html file
    Q.all html.map (file) ->

      # run the opra builder
      opraBuild("public/#{file}", opraOptions)

      # write the file to disk
      .then (data) ->
        powerfsWriteFile "tmp/" + file, data, "utf8"
      .then ->
        compileCount++
        console.log "compiled [#{compileCount}/#{html.length}]"



  # Run the two tracks at the same time
  track1 = Q.all([compileTrack()]).then -> uploadOpraTrack()
  track2 = Q.all([uploadTrack()])

  Q.all([track1, track2]).then ->
    console.log "done"
  .end()
