object @log

attributes :student

# node :actions do |log|	
#   log.logs_by_user(@ats).map { |l|{
#       datetime: l.datetime,
#       action: l.action,
#       tool: l.tool,
#       tool_type: l.tool_type,
#       group: l.action == 'acessou o Solar' ? '' : log.get_allocation_tag
#     }
#   }
# end
puts 'teste 1'
node :actions do |log|	
  puts 'teste'	
  log.logs_by_user2(@ats).map { |l|{
      text: l.name
    }
  }
end
