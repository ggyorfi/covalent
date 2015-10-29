path = require 'path'
minimatch = require 'minimatch'
Module = require 'module'
Context = require './mochatom-context'

unless Module._mochatom

  _module = Module._mochatom =

    _prevLoad: Module._load
    _cache: {}

    _load: (request, parent, isMain) ->
      filename = Module._resolveFilename request, parent
      ctx = Context.get filename
      unless _module.isTestRelated filename, parent
        return _module._prevLoad request, parent, isMain
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

    resetCache: -> @_cache = {}

    _isTestRelated: (request, parent) ->
      # TODO: check parent???
      return false unless _module._isFileTypeSupported()
      _module._checkPath request, Conf
      request.indexOf("/mochatom/examples/") != -1

    _isFileTypeSupported: (filename) ->
      ext = path.extname(filename).toLowerCase();
      [ '.js', '.es6', '.coffee' ].indexOf(ext) != -1

    _checkPath: (filename, src) ->
      if Array.isArray src
        for item in src
          return false if item.charAt(0) == '!' and minimatch filename, item.substring 1
        for item in src
          return true if item.charAt(0) != '!' and minimatch filename, item
      else
        return minimatch filename, src
      return false

  Module._load = _module._load

module.exports = Module._mochatom
