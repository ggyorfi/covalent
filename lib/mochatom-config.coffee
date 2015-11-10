path = require 'path'
glob = require 'glob'


class Config

  constructor: ->
    @_projects = {}
    @_promise = new Promise (resolve) => @_resolve = resolve


  init: (options) ->
    Promise.all(@_loadConfigFiles()).then => @_resolve()


  ready: ->
    @_promise


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
            @_projects[root + path.sep] = config
          return # prevent exidental return in promise then


  _prepareConfigObject: (config, dirPath) ->
    addRoot = (value) -> value.replace /\{ROOT\}/g, dirPath

    prepSrc = (src) ->
      unless Array.isArray src then addRoot src
      else addRoot value for value, i in src

    comp.src = prepSrc comp.src for own name, comp of config.compilers when comp.src?
    config.src = prepSrc config.src
    config.spec = prepSrc config.spec
    if config.load?
      config.load = [ config.load ] unless Array.isArray config.load
      config.load = prepSrc config.load
      config._loadFiles = []
      for pattern in config.load
        console.log "1>", pattern
        files = glob.sync pattern
        console.log "2>", files
        config._loadFiles.push file for file in files if files
      console.log config

    config.env[key] = addRoot value for own key, value of config.env


  lookup: (filename) ->
    return config for key, config of @_projects when filename.indexOf(key) == 0


module.exports = Config
