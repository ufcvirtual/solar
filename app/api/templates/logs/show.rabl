object @log

attributes :student

node :actions do |log|	
  log.logs_by_user(@date_start, @date_end, @ats).map { |l|{
      datetime: l.datetime,
      action: l.action,
      tool: l.tool,
      tool_type: l.tool_type,
      group: l.action == 'acessou o Solar' ? '' : log.get_allocation_tag
    }
  }
end
