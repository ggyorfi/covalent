vm = require 'vm'
path = require 'path'
chai = require 'chai'
Module = require 'module'
Context = require './mochatom-context'
Mocha = require 'mocha'
{CompositeDisposable} = require 'atom'


class ContextManager


  constructor: ->
    @_config = null
    @_contexCache = {}
    @_moduleCache = null
    @_prevModuleLoad = null
    @_sandbox = null
    @_isModuleHackEnabled = false
    @_decorationManager


  init: (options) ->
    @_config = options.config
    @_decorationManager = options.decorationManager
    @_prevModuleLoad = Module._load
    Module._load = @_moduleLoad
    Mocha.prototype.loadFiles = @_mochaLoadFiles
    Mocha.prototype._mochatomManager = this


  _moduleLoad: (request, parent, isMain) =>
    return @_prevModuleLoad request, parent, isMain unless @_isModuleHackEnabled
    filename = Module._resolveFilename request, parent
    return @_prevModuleLoad request, parent, isMain unless ctx = @get filename
    cachedModule = @_moduleCache[filename]
    return cachedModule.exports if cachedModule
    m = new Module filename, parent
    @_moduleCache[filename] = module
    m.filename = filename;
    m.paths = Module._nodeModulePaths path.dirname filename
    ctx.compile m
    m.loaded = true
    # handle exceptions + remove from cache
    m.exports


  _mochaLoadFiles: (fn) ->
    suite = @suite
    pending = @files.length
    @files.forEach (file) =>
      file = path.resolve file
      suite.emit 'pre-require', @_mochatomManager._sandbox, file, this
      suite.emit 'require', require(file), file, this
      suite.emit 'post-require', @_mochatomManager._sandbox, file, this
      --pending || (fn && fn())


  start: ->
    @_isModuleHackEnabled = true
    @_moduleCache = {}
    @_sandbox = {}
    vm.createContext @_sandbox
    @_sandbox.console = console
    @_sandbox.global = @_sandbox
    # Context._sandbox.__srcroot = "../lib/"
    @_sandbox.expect = chai.expect


  stop: ->
    @_isModuleHackEnabled = false
    @_moduleCache = null
    @_sandbox = null


  get: (filename) ->
    # early test for file type
    ext = path.extname(filename).toLowerCase();
    return unless ext == '.js' or ext == '.coffee' or ext == '.es6'

    # early test for config
    return unless config = @_config.lookup filename

    return ctx if ctx = @_contexCache[filename]
    ctx = new Context filename, config, @_decorationManager # TODO: IOC container???
    ctx.manager = this
    @_contexCache[filename] = ctx


  registerEditor: (editor) =>
    return unless ctx = @get editor.getPath()
    ctx.editor = editor # TODO: -> attachEditor
    subscriptions = new CompositeDisposable

    subscriptions.add editor.onDidDestroy ->
      delete ctx.editor # TODO: -> detachEditor
      subscriptions.dispose()

    subscriptions.add editor.onDidSave ->
      ctx.run()

    subscriptions.add editor.onDidStopChanging =>
      ctx.run() if ctx.config?.runOnFly

    subscriptions.add editor.onDidChangeCursorPosition =>
      @_decorationManager.updateErrorMessage()


  compileModule: (m, content, filename) ->
    r = (path) -> m.require path
    r.resolve = (request) -> Module._resolveFilename request, m
    r.main = process.mainModule
    r.extensions = Module._extensions
    r.cache = Module._cache # ???
    dirname = path.dirname filename
    wrapper = Module.wrap "\n#{content}"
    console.groupCollapsed filename
    console.log @_addLineNumbers wrapper # TODO: config
    console.groupEnd()
    compiledWrapper = vm.runInContext wrapper, @_sandbox, filename: "#{filename}:MOCHATOM"
    args = [ m.exports, r, m, filename, dirname ]
    compiledWrapper.apply m.exports, args

  _addLineNumbers: (src) ->
    l = 2
    "  1 " + src.replace /\n/mg, ->
      if l < 10 then "\n  #{l++} "
      else if l < 100 then "\n #{l++} "

  coverage: ->
    @_sandbox.__coverage__


module.exports = ContextManager
