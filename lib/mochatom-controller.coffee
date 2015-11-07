class MochatomController


  constructor: ->
    @_view = null


  init: (options) ->
    @_view = options.view
    @_modalPanel = atom.workspace.addBottomPanel item: @_view.getElement(), visible: false


  show: (msg) ->
    @_view.updateMessage msg
    @_modalPanel.show()


  hide: ->
    @_modalPanel.hide()


  destroy: ->
    @_modalPanel.destroy()


module.exports = MochatomController
