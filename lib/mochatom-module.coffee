path = require 'path'
Module = require 'module'
Context = require './mochatom-context'

unless Module._mochatom

  _module = Module._mochatom =

    _prevLoad: Module._load
    _cache: {}

    isTestRelated: (request, parent) ->
      request.indexOf("/Users/gabor.gyorfi/Projects/breezy/vdom") == 0

    _load: (request, parent, isMain) ->
      filename = Module._resolveFilename request, parent
      unless _module.isTestRelated filename, parent
        return _module._prevLoad request, parent, isMain
      cachedModule = _module._cache[filename]
      return cachedModule.exports if cachedModule
      m = new Module filename, parent
      _module._cache[filename] = module
      m.filename = filename;
      m.paths = Module._nodeModulePaths path.dirname filename
      Context.get(filename).compile m
      m.loaded = true
      # handle exceptions + remove from cache
      m.exports

    resetCache: -> @_cache = {}

  Module._load = _module._load

module.exports = Module._mochatom
