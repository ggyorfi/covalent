path = require 'path'

module.exports = Config =

  _configs: {}

  init: (callback) ->
    Promise.all(@_loadConfigFiles()).then callback

  _loadConfigFiles: ->
    for dir in atom.project.getDirectories()
      do (dir) =>
        file = dir.getFile 'mochatom.json'
        file.read(true).then (data) =>
          if data
            root = dir.getPath()
            config = JSON.parse data
            config._root = root + path.sep
            @_prepareConfigObject config, root
            @_configs[root + path.sep] = config
          return # prevent exidental return in promise then

  _prepareConfigObject: (config, dirPath) ->
    addRoot = (value) -> value.replace /\{ROOT\}/g, dirPath

    prepSrc = (src) ->
      unless Array.isArray src then addRoot src
      else addRoot value for value, i in src

    comp.src = prepSrc comp.src for own name, comp of config.compilers when comp.src?
    config.src = prepSrc config.src
    config.spec = prepSrc config.spec
    config.helpers = prepSrc config.helpers if config.helpers?
    config.env[key] = addRoot value for own key, value of config.env

  lookup: (filename) ->
    return config for key, config of @_configs when filename.indexOf(key) == 0
