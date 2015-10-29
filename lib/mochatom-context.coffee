fs = require 'fs'
path = require 'path'
vm = require 'vm'
babel = require 'babel-core'
Module = require 'module'

class Context

  @_errorSandbox: null
  @_testSandbox: null


  @start: ->
    Context._errorSandbox = {}
    vm.createContext Context._errorSandbox
    Context._errorSandbox.console = console
    Context._errorSandbox.global = Context._errorSandbox
    Context._errorSandbox.__srcroot = "../lib/"

    Context._errorSandbox.expect = require('chai').expect

    Context._testSandbox = {}
    vm.createContext Context._testSandbox
    Context._testSandbox.console = console
    Context._testSandbox.global = Context._testSandbox
    Context._errorSandbox.__srcroot = "../lib/"


  @get: (filename) -> new Context filename


  constructor: (@filename) ->
    @content = fs.readFileSync @filename, 'utf8'

    # stripe BOM
    if @content.charCodeAt(0) == 0xFEFF
      @content = @content.slice 1

    @spec = @filename.indexOf("/mochatom/examples/es6/spec") != -1
    @src = @filename.indexOf("/mochatom/examples/es6/lib") != -1


  compile: (m) ->
    transpiled = babel.transform @content, sourceMaps: true, filename: @filename
    @map = transpiled.map
    @_compileModule m, transpiled.code, Context._errorSandbox


  _compileModule: (m, content, sandbox) ->
    r = (path) -> m.require path
    r.resolve = (request) -> Module._resolveFilename request, m
    r.main = process.mainModule
    r.extensions = Module._extensions
    r.cache = Module._cache # ???
    dirname = path.dirname @filename
    wrapper = Module.wrap content
    compiledWrapper = vm.runInContext wrapper, sandbox, filename: @filename
    args = [ m.exports, r, m, @filename, dirname ]
    compiledWrapper.apply m.exports, args


  # transpile: ->
  #   Module.prototype._mochatomCompileModule transpiled.code, filePath, sandbox2
  #   instrumented = instrumenter.instrumentSync src, filePath
  #   return Module.prototype._mochatomCompileModule instrumented, filePath, sandbox


module.exports = Context
