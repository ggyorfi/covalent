path = require 'path'


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
        file = dir.getFile 'covalent.json'
        file.read(true).then (data) =>
          if data
            root = dir.getPath()
            config = JSON.parse data
            config._root = root + path.sep
            @_setDeafaultOtions config
            @_prepareConfigObject config, root
            @_projects[root + path.sep] = config
          return # prevent exidental return in promise then


  _prepareConfigObject: (config, root) ->
    comp.src = @_prepSrc comp.src, root for own name, comp of config.compilers when comp.src?
    config.src = @_prepSrc config.src, root
    config.spec = @_prepSrc config.spec, root
    config.load = @_prepSrc config.load, root if config.load
    config.env[key] = @_addRoot value, root for own key, value of config.env


  _setDeafaultOtions: (config) ->
    opts = config.options ? {}
    unless opts.jasmin
      unless opts.mocha
        opts.mocha = ui: "bdd"
      unless opts.mocha.chai
        opts.mocha.chai = interface: "expect", "sinon-chai": true
      unless opts.sinon == false
        opts.sinon = true
    config.options = opts


  _addRoot: (value, root) ->
    value = value.replace /\{ROOT\}/g, root
    value.replace /\/\//g, '/'


  _prepSrc: (src, root) ->
    unless Array.isArray src then @_addRoot src, root
    else @_addRoot value, root for value, i in src


  lookup: (filename) ->
    return config for key, config of @_projects when filename.indexOf(key) == 0


module.exports = Config
