fs = require 'fs'
path = require 'path'
vm = require 'vm'
babel = require 'babel-core'
minimatch = require 'minimatch'
isparta = require 'isparta'
istanbul = require 'istanbul'
{CompositeDisposable} = require 'atom'
Module = require 'module'
Config = require './mochatom-config'


class Context

  @_cache: {}
  @_sandbox: null
  @_jsInstrumenter: new istanbul.Instrumenter
  @_es6Instrumenter: new isparta.Instrumenter


  @start: ->
    Context._sandbox = {}
    vm.createContext Context._sandbox
    Context._sandbox.console = console
    Context._sandbox.global = Context._sandbox
    Context._sandbox.__srcroot = "../lib/"

    Context._sandbox.expect = require('chai').expect


  @get: (filename) ->
    # early test for file type
    ext = path.extname(filename).toLowerCase();
    return unless ext == '.js' or ext == '.coffee' or ext == '.es6'

    # early test for config
    return unless config = Config.lookup filename

    return ctx if ctx = Context._cache[filename]
    Context._cache[filename] = new Context filename, config


  @registerEditor: (editor) ->
    return unless ctx = Context.get editor.getPath()
    subscriptions = new CompositeDisposable

    subscriptions.add editor.onDidDestroy ->
      delete Context._cache[tx.filename]
      subscriptions.dispose()

    subscriptions.add editor.onDidSave ->
      console.log onDidSave ctx.filename

    console.log "====>"


  constructor: (@filename, @config) ->
    @compiler = @src = @spec = false
    @testRelated = @src = true if @_checkPath @config.src
    @testRelated = @spec = true if @_checkPath @config.spec
    for compiler, config of @config.compilers when @_checkPath config.src
        @compiler = compiler
        break

  _loadFromFile: ->
    content = fs.readFileSync @filename, 'utf8'
    content.slice 1 if content.charCodeAt(0) == 0xFEFF # stripe BOM
    return content


  _checkPath: (patterns) ->
    if Array.isArray patterns
      for pattern in patterns
        return false if pattern.charAt(0) == '!' and minimatch @filename, pattern.substring 1
      for pattern in patterns
        return true if pattern.charAt(0) != '!' and minimatch @filename, pattern
    else
      return minimatch @filename, patterns
    return false


  _load: ->
    @_loadFromFile()


  compile: (m) ->
    src = @_load()
    if @src
      if @compiler == 'babel'
        code = Context._es6Instrumenter.instrumentSync src, @filename
      else
        code = Context._jsInstrumenter.instrumentSync src, @filename
    else
      if @compiler == 'babel'
        transpiled = babel.transform src, sourceMaps: true, filename: @filename
        @map = transpiled.map
        code = transpiled.code
      else
        code = src
    @_compileModule m, code, Context._sandbox


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


module.exports = Context
