class DecorationManager


  constructor: ->
    @_decorations = {}
    @_todo = null


  init: (options) ->
    @_todo = options.todo # TODO: :)


  addDecoration: (ctx, line, className, errorMessage) ->
    unless desc = @_decorations[ctx.filename]
      desc = @_decorations[ctx.filename] =
        ctx: ctx
        queue: []
        decorations: []
        errorMessages: {}
    desc.queue.push
      line: line
      className: className
      errorMessage: errorMessage


  applyDecorations: () ->
    for filename, desc of @_decorations
      if desc.ctx.editor and desc.queue.length > 0
        decoration.destroy() for decoration in desc.decorations
        desc.decorations.length = 0
        for item in desc.queue
          range = [ [ item.line, 0 ], [ item.line, 0 ] ]
          marker = desc.ctx.editor.markBufferRange range, invalidate: 'never'
          desc.decorations.push desc.ctx.editor.decorateMarker marker, type: 'line-number', class: item.className
          if item.errorMessage
            desc.errorMessages[item.line] = "#{item.errorMessage}"
        desc.queue.length = 0
    @updateErrorMessage()


  updateErrorMessage: =>
    item = atom.workspace.getActivePaneItem()
    desc = @_decorations[item?.getPath?()]
    if desc?.ctx.editor?
      row = desc.ctx.editor.getCursorBufferPosition().row
      errorMessage = desc.errorMessages[row]
      if errorMessage
        @_todo.mochatomView.message.innerHTML = errorMessage
        @_todo.modalPanel.show()
        return
    @_todo.modalPanel.hide()






module.exports = DecorationManager
