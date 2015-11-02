fs = require 'fs'
path = require 'path'
babel = require 'babel-core'
minimatch = require 'minimatch'
isparta = require 'isparta'
istanbul = require 'istanbul'
Module = require 'module'
Mocha = require 'mocha'
Base = Mocha.reporters.Base
{SourceMapConsumer} = require 'source-map'

class Context

  @_jsInstrumenter: new istanbul.Instrumenter
  @_es6Instrumenter: new isparta.Instrumenter


  constructor: (@filename, @config) ->
    @_decorations = []
    @_errorMessages = []
    @compiler = @src = @spec = false
    @testRelated = @src = true if @_checkPath @config.src
    @testRelated = @spec = true if @_checkPath @config.spec
    for compiler, config of @config.compilers when @_checkPath config.src
        @compiler = compiler
        break


  run: () ->
    @removeAllDecorations();
    @manager.start()
    mocha = new Mocha();
    mocha.reporter @_mochaReporter
    mocha.addFile @filename
    try
      mocha.run @_showResults
    catch err
      @_reportError err

  _mochaReporter: (mochaRunner) =>
    # context = Module.prototype._mochatomActiveContext # TODO: better way???
    Base.call @, mochaRunner
    mochaRunner.on 'fail', (test) =>
      # console.log "FAIL", test, this
      @_reportError test.err


  _reportError: (err) ->
    console.log err.stack if @config.debug
    rows = err.stack.split /[\r\n]/
    msg = "<strong>#{err.message}</strong>"
    rx = new RegExp "(#{@config._root}[^:]*):.*?(\\d+)(?::(\\d+))?"
    for row in rows
      row.replace rx, (str, filename, line, pos) =>
        if ctx = @manager.get filename
          if err._compileError
            offset = 0
          else
            offset = -1
          line = Math.max (parseInt line) + offset, 1
          pos = parseInt pos
          if ctx.map?
            consumer = new SourceMapConsumer ctx.map
            origpos = consumer.originalPositionFor
              line: line,
              column: pos,
              bias: SourceMapConsumer.LEAST_UPPER_BOUND
            line = origpos.line
          ctx.addDecoration line - 1, 0, 'line-number', 'test-error', msg


  compile: (m) ->
    src = @_load()
    if @src
      try
        if @compiler == 'babel'
          code = Context._es6Instrumenter.instrumentSync src, @filename
        else
          code = Context._jsInstrumenter.instrumentSync src, @filename
      catch err
        err._compileError = true
        throw err
    else
      if @compiler == 'babel'
        transpiled = babel.transform src, sourceMaps: true, filename: @filename
        @map = transpiled.map
        code = transpiled.code
      else
        code = src
    @manager.compileModule m, code, @filename


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
    return @editor.getText() if @editor?
    @_loadFromFile()


  _showResults: =>
    cov = @manager.coverage()
    if cov?
      collector = new istanbul.Collector
      collector.add cov
      collector.files().forEach (filename) =>
        ctx = @manager.get filename
        if ctx?.editor?
          ctx.removeAllDecorations()
          report = @_buildReport collector.fileCoverageFor filename
          for lc, line in report when lc != undefined
            className = if lc > 0 then 'tested-line' else 'untested-line'
            ctx.addDecoration line - 1, 0, 'line-number', className
    # @_updateErrorMessage activeContext

    @manager.stop()


  removeAllDecorations: ->
    decoration.destroy() for decoration in @_decorations
    @_decorations.length = 0
    @_errorMessages = {}
    # @modalPanel.hide()


  addDecoration: (line, pos, type, className, errorMessage) ->
    range = [ [ line, pos ], [ line, pos ] ]
    marker = @editor.markBufferRange range, invalidate: 'never'
    @_decorations.push @editor.decorateMarker marker, type: type, class: className
    if errorMessage
      @_errorMessages[line] = "#{errorMessage}"


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

  # _updateErrorMessage: () ->
  #   item = atom.workspace.getActivePaneItem()
  #   context = context.manager.getByPath item?.getPath?()
  #   context?.updateErrorMessage()



module.exports = Context
