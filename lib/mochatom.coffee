MochatomView = require './mochatom-view'
{CompositeDisposable} = require 'atom'
ContextManager = require './mochatom-context-manager'
TestRunner = require './mochatom-test-runner'

class Mochatom

  constructor: ->
    @mochatomView = null
    @modalPanel = null
    @subscriptions = null
    @_contextManager = null

  activate: (state) ->
    console.log "Activate Mochatom"

    @_contextManager = new ContextManager new TestRunner

    @mochatomView = new MochatomView state.mochatomViewState
    @modalPanel = atom.workspace.addBottomPanel item: @mochatomView.getElement(), visible: false

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    # @subscriptions.add atom.commands.add 'atom-workspace', 'mochatom:toggle': => @toggle()

    @subscriptions.add atom.project.onDidChangePaths (projectPaths) ->
      # TODO: implement this
      console.log "onDidChangePaths", projectPaths

    @_contextManager.init =>
      # register text editor observer
      @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
         context = @_contextManager.getByPath item.getPath?()
         context?.updateErrorMessage()

      @subscriptions.add atom.workspace.observeTextEditors @registerTextEditor

  registerTextEditor: (editor) =>
    context = @_contextManager.register editor
    if context
      context.modalPanel = @modalPanel # TODO: better way??? MVC???
      context.mochatomView = @mochatomView # TODO: better way??? MVC???

      context.run() if context.isSpec()

      subscriptions = new CompositeDisposable

      subscriptions.add editor.onDidDestroy ->
        context.remove()
        subscriptions.dispose()

      subscriptions.add editor.onDidSave ->
        if context.isSrc()
          context.runDependencies()
        else if context.isSpec()
          context.removeAllDepencies()
          context.run()

      subscriptions.add editor.onDidChangeCursorPosition ->
        context.updateErrorMessage()

  deactivate: ->
    console.log "Deactivate Mochatom"
    @subscriptions.dispose()
    @config = {}
    @modalPanel.destroy()
    @mochatomView.destroy()

  serialize: ->
    # mochatomViewState: @mochatomView.serialize()
    @config

  # toggle: ->
  #   console.log 'Start Mochatom!'
  #
  #   if @modalPanel.isVisible()
  #     @modalPanel.hide()
  #   else
  #     @modalPanel.show()

module.exports = new Mochatom
