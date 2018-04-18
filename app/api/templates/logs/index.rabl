collection @logs

attributes :student

node :actions do |log|
  log.logs_by_user(@ats.flatten.uniq).map { |l|{
      datetime: l.datetime,
      action: l.action + l.info,
      tool: l.tool,
      tool_type: l.tool_type,
      group: l.action == 'acessou o Solar' ? '' : log.get_allocation_tag
    }
  }
end

