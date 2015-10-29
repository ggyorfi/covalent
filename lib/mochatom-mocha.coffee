path = require 'path'
Mocha = require 'mocha'
Context = require './mochatom-context'

Mocha.prototype.loadFiles = (fn) ->
  console.log "HIHEHA"
  suite = @suite
  pending = @files.length
  @files.forEach (file) =>
    file = path.resolve file
    suite.emit 'pre-require', Context._errorSandbox, file, this
    suite.emit 'require', require(file), file, this
    suite.emit 'post-require', Context._errorSandbox, file, this
    --pending || (fn && fn())

run: ->
  Context.start()
  mocha = new Mocha();
  mocha.addFile filename
  mocha.run (failures) ->
    console.log "DONE", failures
