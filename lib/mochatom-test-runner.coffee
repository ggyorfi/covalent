Mocha = require 'mocha'
Module = require 'module'
vm = require 'vm'
fs = require 'fs'
path = require 'path'
chai = require 'chai'
sinon = require 'sinon'
babel = require 'babel-core'
sinonChai = require 'sinon-chai'
{Collector} = require 'istanbul'
{Instrumenter} = require 'isparta'
# {Instrumenter} = require 'istanbul'
{allowUnsafeNewFunction} = require 'loophole'
{SourceMapConsumer} = require 'source-map'

Base = Mocha.reporters.Base
instrumenter = new Instrumenter

sandbox = null
sandbox2 = null # for sourcemaps
modpaths = null
cache = null

chai.use sinonChai

unless Module.prototype._mochatomDefaultRequire

  Module.prototype._mochatomDefaultRequire = Module.prototype.require
  Module.prototype._mochatomActiveContext = null

  Module.prototype._mochatomCompileModule = (src, filename, sandbox) ->
      allowUnsafeNewFunction ->
        m = new Module
        m.paths = modpaths
        require = (path) -> m.require path
        require.resolve = (request) -> Module._resolveFilename request, m
        require.main = process.mainModule
        # require.extensions = Module._extensions;
        require.cache = cache;
        dirname = path.dirname filename
        wrapper = Module.wrap "\n#{src}"
        compiledWrapper = vm.runInContext wrapper, sandbox, filename: filename
        args = [ m.exports, require, m, filename, dirname ]
        compiledWrapper.apply m.exports, args
        m.exports

  Module.prototype.require = (filePath) ->
    activeContext = Module.prototype._mochatomActiveContext
    if activeContext
      context = activeContext.manager.getByPath filePath
      if context
          if context.isSrc()
            context.addDependency activeContext
            activeContext.addDependency context
            src = context.editor.getText()
            transpiled = babel.transform src, sourceMaps: true, filename: filePath
            context.sourceMap = transpiled.map
            Module.prototype._mochatomCompileModule transpiled.code, filePath, sandbox2
            instrumented = instrumenter.instrumentSync src, filePath
            return Module.prototype._mochatomCompileModule instrumented, filePath, sandbox
          else if context.isSpec()
            src = context.editor.getText()
            return Module.prototype._mochatomCompileModule src, filePath, sandbox
    Module.prototype._mochatomDefaultRequire.call this, filePath


class Runner

  run: (context) ->
    Module.prototype._mochatomActiveContext = context
    mocha = new Mocha ui: 'bdd' # TODO: reuse mocha???

    context.removeAllDecorations()
    mocha.reporter @_mochaReporter

    modpaths = []
    cache = {}
    dir = context.dir
    while dir != path.sep
      modpaths.push path.join dir, 'node_modules'
      dir = path.dirname dir

    # init sandbox
    sandbox = {}
    vm.createContext sandbox
    sandbox.global = sandbox
    Object.defineProperty sandbox, 'describe', get: -> Mocha.describe
    Object.defineProperty sandbox, 'it', get: -> Mocha.it
    Object.defineProperty sandbox, 'beforeEach', get: -> Mocha.beforeEach
    Object.defineProperty sandbox, 'afterEach', get: -> Mocha.afterEach
    Object.defineProperty sandbox, 'before', get: -> Mocha.before
    Object.defineProperty sandbox, 'after', get: -> Mocha.after
    sandbox.console = console
    sandbox.expect = chai.expect
    sandbox.sinon = sinon
    sandbox[key] = value for key, value of context.config.env

    # init sandbox2 for error report
    sandbox2 = {}
    vm.createContext sandbox2
    sandbox2.global = sandbox2
    sandbox2.console = console
    sandbox2[key] = value for key, value of context.config.env

    for helper in context.config.helpers
      helperPath = path.join context.dir, helper
      helperSrc = fs.readFileSync helperPath, 'utf8'
      Module.prototype._mochatomCompileModule helperSrc, helperPath, sandbox
    mocha.addFile context.filePath

    try
      mocha.run @_showResults
    catch err
      done = false
      rx = new RegExp "(.*):.*\\((\\d+):(\\d+)\\)"
      msg = "<strong>#{err.message}</strong>"
      err.message.replace rx, (str, filePath, line, pos) =>
        line = parseInt line - 1
        pos = parseInt pos
        errorContext = context.manager.getByPath filePath
        errorContext?.addDecoration line, pos, 'line-number', 'test-error', msg
        @_updateErrorMessage context
        done = true
      @_reportError err, context # unless done
      @_updateErrorMessage context

  _reportError: (err, context) ->
    console.log err.stack if context?.config.debug
    rows = err.stack.split /[\r\n]/
    msg = "<strong>#{err.message}</strong>"
    rx = new RegExp "(#{context.dir}[^:]*):(\\d+)(?::(\\d+))?"
    for row in rows
      row.replace rx, (str, filePath, line, pos) ->
        fileContext = context.manager.getByPath filePath
        if fileContext?
          line = (parseInt line) - 1
          pos = parseInt pos
          if fileContext?.sourceMap?
            consumer = new SourceMapConsumer fileContext.sourceMap
            origpos = consumer.originalPositionFor
              line: line,
              column: pos,
              bias: SourceMapConsumer.LEAST_UPPER_BOUND
            line = origpos.line
          fileContext.addDecoration line - 1, 0, 'line-number', 'test-error', msg

  _mochaReporter: (mochaRunner) =>
    context = Module.prototype._mochatomActiveContext # TODO: better way???
    Base.call @, mochaRunner
    mochaRunner.on 'fail', (test) =>
      @_reportError test.err, context

  _showResults: =>
    activeContext = Module.prototype._mochatomActiveContext
    contextManager = activeContext.manager
    collector = new Collector
    collector.add sandbox.__coverage__
    collector.files().forEach (fname) =>
      context = contextManager.getByPath fname
      context.removeAllDecorations()
      report = @_buildReport collector.fileCoverageFor fname
      for lc, line in report when lc != undefined
        className = if lc > 0 then 'tested-line' else 'untested-line'
        context.addDecoration line - 1, 0, 'line-number', className
    @_updateErrorMessage activeContext

  _buildReport: (cov) ->
    report = []
    for idx, s of cov.s
      info = cov.statementMap[parseInt idx]
      if s > 0
        for line in [ info.start.line .. info.end.line ]
          report[line] = (report[line] || 0) + 1
      else
        for line in [ info.start.line .. info.end.line ]
          report[line] = 0
    report

  _updateErrorMessage: (context) ->
    item = atom.workspace.getActivePaneItem()
    context = context.manager.getByPath item?.getPath?()
    context?.updateErrorMessage()

module.exports = Runner
