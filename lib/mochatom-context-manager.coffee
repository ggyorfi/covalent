path = require 'path'
minimatch = require 'minimatch'
Context = require './mochatom-context'

class ContextManager

    constructor: (@_runner) ->
      @_contexts = {}
      @_config = {}

    init: (callback) ->
        Promise.all(@_loadConfigFiles()).then callback

    register: (editor) ->
      filePath = editor.getPath()
      if @_isSupportedFileType filePath
          for dir, config of @_config
            if @_checkPath filePath, config.src
              return @_contexts[filePath] = new Context 'src', editor, filePath, dir, config, this
            if @_checkPath filePath, config.spec
              return @_contexts[filePath] = new Context 'spec', editor, filePath, dir, config, this
          return

    _checkPath: (filePath, src) ->
      # TODO: add negation support
      if Array.isArray src
        return true for item in src when minimatch filePath, item
      else
        return minimatch filePath, src
      return false

    _isSupportedFileType: (filePath) ->
        path.extname(filePath).toLowerCase() == '.js'

    remove: (context) ->
      delete @_contexts[context.filePath]

    _loadConfigFiles: ->
      for dir in atom.project.getDirectories()
        do (dir) =>
          file = dir.getFile 'mochatom.json'
          file.read(true).then (data) =>
            if data
              dirPath = dir.getPath()
              config = JSON.parse data
              @_prepareConfigObject config, dirPath
              @_config[dirPath] = config
            return # prevent exidental return in promise then

    _prepareConfigObject: (config, dirPath) ->
      addRoot = (value) -> value.replace /\{ROOT\}/g, dirPath

      prepSrc = (src) ->
        unless Array.isArray src then addRoot src
        else addRoot value for value, i in src

      comp.src = prepSrc comp.src for own name, comp of config.compilers when comp.src?
      config.src = prepSrc config.src
      config.spec = prepSrc config.spec
      config.env[key] = addRoot value for own key, value of config.env

      console.log config

    getByEditor: (editor) ->
      @_contexts[editor.getPath()]

    getByPath: (filePath) ->
      @_contexts[filePath]

module.exports = ContextManager
