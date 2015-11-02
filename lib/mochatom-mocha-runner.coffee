path = require 'path'
Module = require './mochatom-module'

console.log Module, ContextManager


module.exports =


  # _showResults: =>
  #   activeContext = Module.prototype._mochatomActiveContext
  #   contextManager = activeContext.manager
  #   if sandbox.__coverage__?
  #     collector = new Collector
  #     collector.add sandbox.__coverage__
  #     collector.files().forEach (fname) =>
  #       context = contextManager.getByPath fname
  #       context.removeAllDecorations()
  #       report = @_buildReport collector.fileCoverageFor fname
  #       for lc, line in report when lc != undefined
  #         className = if lc > 0 then 'tested-line' else 'untested-line'
  #         context.addDecoration line - 1, 0, 'line-number', className
  #   @_updateErrorMessage activeContext
  #
  # _buildReport: (cov) ->
  #   report = []
  #   for idx, s of cov.s
  #     info = cov.statementMap[parseInt idx]
  #     if s > 0
  #       for line in [ info.start.line .. info.end.line ]
  #         report[line] = (report[line] || 0) + 1
  #     else
  #       for line in [ info.start.line .. info.end.line ]
  #         report[line] = 0
  #   report
  #
  # _updateErrorMessage: (context) ->
  #   item = atom.workspace.getActivePaneItem()
  #   context = context.manager.getByPath item?.getPath?()
  #   context?.updateErrorMessage()
