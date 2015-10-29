MochatomView = require './mochatom-view'
{CompositeDisposable} = require 'atom'
mochatomModule = require './mochatom-module'
Config = require './mochatom-config'
Mocha = require './mochatom-mocha'

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

    Promise.all(Config.loadConfigFiles()).then ->
      console.log Config._config

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @mochatomView.destroy()

  serialize: ->
    mochatomViewState: @mochatomView.serialize()

  toggle: ->
    if @modalPanel.isVisible()
      console.log 'Hide Mochatom'
      @modalPanel.hide()
      mochatomModule.resetCache()
    else
      console.log 'Run Mochatom'
      @modalPanel.show()
      Mocha.run "/Users/gabor.gyorfi/.atom/packages/mochatom/examples/es6/spec/Test-spec.js"
