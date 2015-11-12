ErrorView = require './error-view'
MainController = require './main-controller'
{CompositeDisposable} = require 'atom'
Config = require './config'
ContextManager = require './context-manager'
DecorationManager = require './decoration-manager'

class Covalent


  constructor: ->
    @_view = null
    @_controller = null
    @_subscriptions = null
    @_decorationManager = null
    @_contextManager = null
    @_config = null


  activate: (state) ->
    @_createDependencies()
    @_initDependencies state


  _createDependencies: ->
    @_view = new ErrorView
    @_controller = new MainController
    @_subscriptions = new CompositeDisposable
    @_decorationManager = new DecorationManager
    @_contextManager =  new ContextManager
    @_config = new Config


  _initDependencies: (state) ->
    @_config.init()
    @_config.ready().then =>
      @_view.init state: state.viewState
      @_controller.init view: @_view
      @_decorationManager.init controller: @_controller
      @_contextManager.init config: @_config, decorationManager: @_decorationManager
      @_subscriptions.add atom.workspace.onDidChangeActivePaneItem @_decorationManager.updateErrorMessage
      @_subscriptions.add atom.workspace.observeTextEditors @_contextManager.registerEditor
      @_subscriptions.add atom.commands.add 'atom-workspace', 'covalent:update': @update
      @_subscriptions.add atom.project.onDidChangePaths (projectPaths) ->
        # TODO: implement this
        console.log "onDidChangePaths", projectPaths


  deactivate: ->
    @_controller.destroy()
    @_subscriptions.dispose()
    @_view.destroy()


  serialize: ->
    viewState: @_view.serialize()


  update: =>
    console.log "UPDATE!!!"


module.exports = new Covalent
