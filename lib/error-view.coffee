module.exports = class ErrorView

  constructor: ->
    @_element = null
    @_message = null

  init: (options) ->
    # Create root element
    @_element = document.createElement 'div'
    @_element.classList.add 'covalent'

    # Create message element
    @_message = document.createElement 'div'
    @_message.classList.add 'message'
    @_element.appendChild @_message

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @_element.remove()

  getElement: ->
    @_element

  updateMessage: (msg) ->
    @_message.innerHTML = msg
