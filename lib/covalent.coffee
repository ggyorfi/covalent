ErrorView = require './error-view'
MainController = require './main-controller'
{CompositeDisposable} = require 'atom'
Config = require './config'
ContextManager = require './context-manager'
DecorationManager = require './decoration-manager'

module.exports = Covalent =

  activate: (state) ->
    @_view = new ErrorView
    @_controller = new MainController
    @_subscriptions = new CompositeDisposable
    @_decorationManager = new DecorationManager
    @_contextManager =  new ContextManager
    @_config = new Config

    # boot
    @_config.init()
    @_config.ready().then =>
      @_view.init state: state.viewState
      @_controller.init view: @_view
      @_decorationManager.init controller: @_controller
      @_contextManager.init config: @_config, decorationManager: @_decorationManager
      @_subscriptions.add atom.workspace.onDidChangeActivePaneItem @_decorationManager.updateErrorMessage
      @_subscriptions.add atom.workspace.observeTextEditors @_contextManager.registerEditor
      @_subscriptions.add atom.commands.add 'atom-workspace', 'covalent:update': =>
        console.log "UPDATE!!!"
      @_subscriptions.add atom.project.onDidChangePaths (projectPaths) ->
        # TODO: implement this
        console.log "onDidChangePaths", projectPaths


  deactivate: ->
    @_controller.destroy()
    @_subscriptions.dispose()
    @_view.destroy()

  serialize: ->
    viewState: @_view.serialize()

  toggle: ->
    console.log "Covalent toggle :)"
