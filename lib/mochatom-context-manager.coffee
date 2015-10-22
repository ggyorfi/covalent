path = require 'path'
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
            if filePath.indexOf((path.join dir, config.src.path) + path.sep) == 0
              return @_contexts[filePath] = new Context 'src', editor, filePath, dir, config, this
            if filePath.indexOf((path.join dir, config.spec.path) + path.sep) == 0
              return @_contexts[filePath] = new Context 'spec', editor, filePath, dir, config, this
          return

    _isSupportedFileType: (filePath) ->
        path.extname(filePath).toLowerCase() == '.js'

    remove: (context) ->
      delete @_contexts[context.filePath]

    _loadConfigFiles: ->
      for dir in atom.project.getDirectories()
        do (dir) =>
          file = dir.getFile 'mochatom.json'
          file.read(true).then (data) =>
            @_config[dir.getPath()] = JSON.parse data if data
            return

    getByEditor: (editor) ->
      @_contexts[editor.getPath()]

    getByPath: (filePath) ->
      @_contexts[filePath]

module.exports = ContextManager
