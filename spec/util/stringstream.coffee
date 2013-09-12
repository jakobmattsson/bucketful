stream = require 'stream'

exports.createStream = ->
  written = ""
  output = new stream.Writable()
  output.write = (data) -> this.emit('data', data)
  output.on 'data', (buffer) -> written += buffer.toString()
  output.toString = -> written
  output


exports.override = (original, cb) ->
  (args...) -> cb.apply(this, [original].concat(args))
