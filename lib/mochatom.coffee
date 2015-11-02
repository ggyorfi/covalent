MochatomView = require './mochatom-view'
{CompositeDisposable} = require 'atom'
Config = require './mochatom-config'
ContextManager = require './mochatom-context-manager'

module.exports = Mochatom =

  mochatomView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    console.log "MOCHATOM: Activate"

    @mochatomView = new MochatomView(state.mochatomViewState)
    @modalPanel = atom.workspace.addBottomPanel(item: @mochatomView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'mochatom:toggle': => @toggle()

    @subscriptions.add atom.project.onDidChangePaths (projectPaths) ->
      # TODO: implement this
      console.log "onDidChangePaths", projectPaths

    Config.init =>
      # register text editor observer
      @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
        console.log "onDidChangeActivePaneItem", item
        # context = @_contextManager.getByPath item?.getPath?()
        # context?.updateErrorMessage()

      @subscriptions.add atom.workspace.observeTextEditors ContextManager.registerEditor


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @mochatomView.destroy()

  serialize: ->
    mochatomViewState: @mochatomView.serialize()

  toggle: ->
    if @modalPanel.isVisible()
      console.log 'Disable Mochatom'
      @modalPanel.hide()
    else
      console.log 'Enable Mochatom'
      @modalPanel.show()
