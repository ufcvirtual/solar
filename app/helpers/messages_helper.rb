module MessagesHelper

  def return_messages(userid, type='index', tag=nil)
    query_messages = "select m.*, usm.user_id, f.original_name, u.name, u.nick,
        cast( usm.status & '00000001' as boolean)ehorigem,
        cast( usm.status & '00000010' as boolean)ehlida

      from messages m
        inner join user_messages usm on m.id = usm.message_id
        left join message_files f on m.id = f.message_id
        inner join users u on usm.user_id=u.id
        left join user_message_labels uml on usm.id = uml.user_message_id
        left join message_labels ml on uml.message_label_id = ml.id
        left join allocation_tags at on ml.allocation_tag_id = at.id

      where
        usm.user_id = #{userid}"  #filtra por usuario

    if !tag.nil?
      query_messages += " and ml.title = '#{tag}' "
    end
    
    case type
    when 'trashbox'
      query_messages += " and cast( usm.status & '00000100' as boolean) "     #filtra se eh excluida
    when 'index'
      query_messages += " and cast( usm.status & '00000001' as boolean) "     #filtra se eh origem (default)
      query_messages += " and NOT cast( usm.status & '00000100' as boolean) " #nao esta na lixeira
    when 'outbox'
      query_messages += " and NOT cast( usm.status & '00000001' as boolean) " #filtra se eh destino
      query_messages += " and NOT cast( usm.status & '00000100' as boolean) " #nao esta na lixeira
    end
#puts "\ntag: #{tag}\n\n**********\n#{query_messages}\n**********\n\n"
    return Message.find_by_sql(query_messages)
  end

end
