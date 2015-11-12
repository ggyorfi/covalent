babel = require 'babel-core'
chai = require 'chai'
coffee = require 'coffee-script'
coffeeCoverage = require 'coffee-coverage'
fs = require 'fs'
isparta = require 'isparta'
istanbul = require 'istanbul'
minimatch = require 'minimatch'
Mocha = require 'mocha'
Module = require 'module'
path = require 'path'
glob = require 'glob-all'
{SourceMapConsumer} = require 'source-map'
Base = Mocha.reporters.Base

class Context

  @_pass = null
  @_jsInstrumenter: new istanbul.Instrumenter
  @_es6Instrumenter: new isparta.Instrumenter
  @_coffeeInstrumenter: new coffeeCoverage.CoverageInstrumentor instrumentor: 'istanbul', coverageVar: '__coverage__'
  @_runtimeError: false
  @_activeTest: null


  constructor: (@filename, @config, @decorationManager) ->
    @lastRelatedTest = null
    @lineOffset = 0
    @compiler = @src = @spec = false
    @testRelated = @src = true if @_checkPath @config.src
    @testRelated = @spec = true if @_checkPath @config.spec
    @testRelated = true if @_checkPath @config.load
    for compiler, config of @config.compilers when @_checkPath config.src
      @compiler = compiler
      break


  run: () ->
    # TODO: test long compile to overlap with the next test session!!!
    unless @spec
      @lastRelatedTest?.run()
      return
    Context._activeTest = this
    Context._runtimeError = false
    mocha = @_initMocha "TEST"
    try
      mocha.run =>
        if Context._runtimeError
          cov = @manager.coverage()
          mocha = @_initMocha "REPORT"
          try
            mocha.run => @_end cov
          catch err
            @_reportError err
            @_end cov
        else
          @_end @manager.coverage()
    catch err
      Context._runtimeError = true


  _initMocha: (pass) ->
    Context._pass = pass
    @manager.start @config.env ? {}
    mocha = new Mocha
    mocha.reporter @_mochaReporter
    load = @config.load
    if load
      for filename in glob.sync(load.slice(0), cache: false)
        mocha.addFile filename
    mocha.addFile @filename
    return mocha


  _end: (cov) ->
    @_showResults cov if cov?
    @decorationManager.applyDecorations()
    @manager.stop()


  _mochaReporter: (mochaRunner) =>
    Base.call this, mochaRunner
    mochaRunner.on 'fail', (test) =>
      if Context._pass == "TEST"
        Context._runtimeError = true
      else
        @_reportError test.err


  _reportError: (err) ->
    console.info "%c#{err.stack}", "color: blue" if @debug 'logErrors'
    rows = err.stack.split /[\r\n]/
    msg = "<strong>#{err.message}</strong>"
    rx = new RegExp "(#{@config._root}[^:]*?):.*?(\\d+)(?::(\\d+))?"
    done = false
    for row in rows
      row.replace rx, (str, filename, line, pos) =>
        if ctx = @manager.get filename
          line = (parseInt line) + ctx.lineOffset
          pos = parseInt pos
          if ctx.map?
            consumer = new SourceMapConsumer ctx.map
            origpos = consumer.originalPositionFor
              line: line,
              column: pos,
              bias: SourceMapConsumer.LEAST_UPPER_BOUND
            line = origpos.line
          @decorationManager.addDecoration ctx, line - 1, 'test-error', msg
          done = true
      break if done


  compile: (m) ->
    @decorationManager.update this
    src = @_load()
    @lineOffset = 0
    try
      src = if @src then @_compileSrc src else @_compileTest src
      @manager.compileModule m, src, this
    catch err
      if Context._pass == "TEST"
        Context._runtimeError = true
      else
        throw err


  _compileSrc: (src) ->
    @lastRelatedTest = Context._activeTest
    if Context._pass == "TEST"
      if @compiler == 'babel'
        src = Context._es6Instrumenter.instrumentSync src, @filename
      else if @compiler == 'coffeescript'
        code = Context._coffeeInstrumenter.instrumentCoffee @filename, src
        src = "#{code.init}#{code.js}"
      else
        src = Context._jsInstrumenter.instrumentSync src, @filename
    else # error report mode
      if @compiler == 'babel'
        @map = null
        transpiled = babel.transform src, sourceMaps: true, filename: @filename
        @map = transpiled.map
        src = transpiled.code
      else if @compiler == 'coffeescript'
        src = @_compileCoffe src
      else
        @lineOffset = -1
    return src


  _compileCoffe: (src) ->
    @lineOffset = -1
    @map = null
    try
      compiled = coffee.compile src, filename: @filename, sourceMap: true
      @map = compiled.v3SourceMap
      return compiled.js
    catch err
      @lineOffset = 0
      err.message = "#{err}"
      throw err
    return src


  _compileTest: (src) ->
    if @compiler == 'babel'
      @lineOffset = -1
      @map = null
      try
        transpiled = babel.transform src, sourceMaps: true, filename: @filename
        @map = transpiled.map
        src = transpiled.code
      catch err
        @lineOffset = 0
        throw err
    else if @compiler == 'coffeescript'
      src = @_compileCoffe src
    return src


  _loadFromFile: ->
    content = fs.readFileSync @filename, 'utf8'
    content.slice 1 if content.charCodeAt(0) == 0xFEFF # stripe BOM
    return content


  _checkPath: (patterns) ->
    debug = @debug 'logFilters'
    console.log "match:", @filename if debug
    if Array.isArray patterns
      for pattern in patterns
        exclude = pattern.charAt(0) == '!' and minimatch @filename, pattern.substring 1
        console.info "  exclude:", pattern, exclude if debug
        return false if exclude
      for pattern in patterns
        include = pattern.charAt(0) != '!' and minimatch @filename, pattern
        console.info "  include:", pattern, include if debug
        return true if include
    else
      include = minimatch @filename, patterns
      console.info "  include:", patterns, include if debug
      return include
    return false

  _load: ->
    return @editor.getText() if @editor?
    @_loadFromFile()


  _showResults: (cov) =>
    if cov?
      collector = new istanbul.Collector
      collector.add cov
      collector.files().forEach (filename) =>
        ctx = @manager.get filename
        if ctx?.editor?
          report = collector.fileCoverageFor filename
          for line, lc of report.l
            className = if lc > 0 then 'tested-line' else 'untested-line'
            @decorationManager.addDecoration ctx, parseInt(line) - 1, className
      @decorationManager.applyDecorations()

    @manager.stop()


  debug: (functionality) ->
    @config.debug == true or @config.debug?[functionality]

module.exports = Context
