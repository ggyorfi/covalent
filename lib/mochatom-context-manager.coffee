vm = require 'vm'
path = require 'path'
chai = require 'chai'
Module = require 'module'
Config = require './mochatom-config'
Context = require './mochatom-context'
Mocha = require 'mocha'
{CompositeDisposable} = require 'atom'


_module =

  _prevLoad: Module._load
  _cache: {}
  _enabled: false

  _load: (request, parent, isMain) ->
    return _module._prevLoad request, parent, isMain unless _module._enabled
    filename = Module._resolveFilename request, parent
    return _module._prevLoad request, parent, isMain unless ctx = ContextManager.get filename
    cachedModule = _module._cache[filename]
    return cachedModule.exports if cachedModule
    m = new Module filename, parent
    _module._cache[filename] = module
    m.filename = filename;
    m.paths = Module._nodeModulePaths path.dirname filename
    ctx.compile m
    m.loaded = true
    # handle exceptions + remove from cache
    m.exports

  start: ->
    @_enabled = true

  stop: ->
    @_enabled = false
    @_cache = {}

Module._load = _module._load


Mocha.prototype.loadFiles = (fn) ->
  suite = @suite
  pending = @files.length
  @files.forEach (file) =>
    file = path.resolve file
    suite.emit 'pre-require', ContextManager._sandbox, file, this
    suite.emit 'require', require(file), file, this
    suite.emit 'post-require', ContextManager._sandbox, file, this
    --pending || (fn && fn())


module.exports = ContextManager =

  _cache: {}
  _sandbox: {}


  start: ->
    _module.start()
    vm.createContext @_sandbox
    @_sandbox.console = console
    @_sandbox.global = @_sandbox
    # Context._sandbox.__srcroot = "../lib/"
    @_sandbox.expect = chai.expect


  stop: ->
    # @_cache = {}
    @_sandbox = {}
    _module.stop()


  get: (filename) ->
    # early test for file type
    ext = path.extname(filename).toLowerCase();
    return unless ext == '.js' or ext == '.coffee' or ext == '.es6'

    # early test for config
    return unless config = Config.lookup filename

    return ctx if ctx = @_cache[filename]
    ctx = new Context filename, config
    ctx.manager = ContextManager
    @_cache[filename] = ctx


  registerEditor: (editor) ->
    return unless ctx = ContextManager.get editor.getPath()
    ctx.editor = editor
    subscriptions = new CompositeDisposable

    subscriptions.add editor.onDidDestroy ->
      # delete Context._cache[tx.filename]
      delete ctx.editor
      subscriptions.dispose()

    subscriptions.add editor.onDidSave ->
      ctx.run() if ctx.spec

    subscriptions.add editor.onDidStopChanging ->
      ctx.run() if ctx.spec


  compileModule: (m, content, filename) ->
    r = (path) -> m.require path
    r.resolve = (request) -> Module._resolveFilename request, m
    r.main = process.mainModule
    r.extensions = Module._extensions
    r.cache = Module._cache # ???
    dirname = path.dirname filename
    wrapper = Module.wrap "\n#{content}"
    compiledWrapper = vm.runInContext wrapper, @_sandbox, filename: filename
    args = [ m.exports, r, m, filename, dirname ]
    compiledWrapper.apply m.exports, args

  coverage: -> @_sandbox.__coverage__
