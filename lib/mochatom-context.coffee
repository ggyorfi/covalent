class Context

  constructor: (@type, @editor, @filePath, @dir, @config, @manager) ->
    @_decorations = []
    @_errorMessages = {}
    @_dependencies = {}

  remove: ->
    @manager.remove this

  isSrc: ->
    return @type == 'src'

  isSpec: ->
    return @type == 'spec'

  addDecoration: (line, pos, type, className, errorMessage) ->
    range = [ [ line, pos ], [ line, pos ] ]
    marker = @editor.markBufferRange range, invalidate: 'never'
    @_decorations.push @editor.decorateMarker marker, type: type, class: className
    if errorMessage
      @_errorMessages[line] = "#{errorMessage}"

  removeAllDecorations: ->
    decoration.destroy() for decoration in @_decorations
    @_decorations.length = 0
    @_errorMessages = {}
    @modalPanel.hide()

  updateErrorMessage: ->
    row = @editor.getCursorBufferPosition().row
    errorMessage = @_errorMessages[row]
    if errorMessage
      @mochatomView.message.innerHTML = errorMessage
      @modalPanel.show()
    else
      @modalPanel.hide()

  run: () ->
    @manager._runner.run this

  addDependency: (context) ->
    @_dependencies[context.filePath] = context

  removeAllDepencies: ->
    for own filePath, context of @_dependencies
      delete context._dependencies[@filePath]
    @_dependencies = {}

  runDependencies: ->
    queue = (item for own key, item of @_dependencies)
    context.run() for context in queue
    return

module.exports = Context
