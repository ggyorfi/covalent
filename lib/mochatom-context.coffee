fs = require 'fs'
path = require 'path'
babel = require 'babel-core'
minimatch = require 'minimatch'
isparta = require 'isparta'
istanbul = require 'istanbul'
Module = require 'module'
Mocha = require 'mocha'


class Context

  @_jsInstrumenter: new istanbul.Instrumenter
  @_es6Instrumenter: new isparta.Instrumenter


  constructor: (@filename, @config) ->
    @compiler = @src = @spec = false
    @testRelated = @src = true if @_checkPath @config.src
    @testRelated = @spec = true if @_checkPath @config.spec
    for compiler, config of @config.compilers when @_checkPath config.src
        @compiler = compiler
        break


  run: () ->
    @manager.start()
    mocha = new Mocha();
    mocha.addFile @filename
    mocha.run => # @_showResults
      @manager.stop()
      console.log "MOCHATOM: Done"


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
    @_loadFromFile()


module.exports = Context
