module.exports = Config =

  _config: {}

  loadConfigFiles: ->
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
    config.helpers = prepSrc config.helpers
    config.env[key] = addRoot value for own key, value of config.env
