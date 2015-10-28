MochatomView = require './mochatom-view'
{CompositeDisposable} = require 'atom'
mochatomModule = require './mochatom-module'
Context = require './mochatom-context'

module.exports = Mochatom =

  mochatomView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @mochatomView = new MochatomView(state.mochatomViewState)
    @modalPanel = atom.workspace.addBottomPanel(item: @mochatomView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'mochatom:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @mochatomView.destroy()

  serialize: ->
    mochatomViewState: @mochatomView.serialize()

  toggle: ->
    console.log 'Mochatom was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
      mochatomModule.resetCache()
    else
      @modalPanel.show()
      Context.start()
      require '/Users/gabor.gyorfi/Projects/breezy/vdom//lib/Class.js'
