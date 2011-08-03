module MessagesHelper

  def return_messages(userid, type='index', tag=nil, page=1, search_text)
    query_messages = "select m.*, usm.user_id, f.original_name, u.name, u.nick,ml.title label,
        cast( usm.status & '00000001' as boolean)ehorigem,
        cast( usm.status & '00000010' as boolean)ehlida,
        cast( usm.status & '00000100' as boolean)ehlixo,
        (select users.name from users inner join user_messages ON users.id = user_messages.user_id
        where user_messages.message_id = m.id and cast( user_messages.status & '00000001' as boolean))sender

      from messages m
        inner join user_messages usm on m.id = usm.message_id
        left join message_files f on m.id = f.message_id
        inner join users u on usm.user_id=u.id
        left join user_message_labels uml on usm.id = uml.user_message_id
        left join message_labels ml on uml.message_label_id = ml.id
        
      where
        usm.user_id = #{userid}"  #filtra por usuario

    if !tag.nil?
      query_messages += " and ml.title = '#{tag}' "
    end
    
    case type
    when 'trashbox'
      query_messages += " and cast( usm.status & '00000100' as boolean) "     #filtra se eh excluida
    when 'index'
      query_messages += " and NOT cast( usm.status & '00000001' as boolean) " #filtra se nao eh origem (eh destino)
      query_messages += " and NOT cast( usm.status & '00000100' as boolean) " #nao esta na lixeira
    when 'outbox'
      query_messages += " and     cast( usm.status & '00000001' as boolean) " #filtra se eh origem (default)
      query_messages += " and NOT cast( usm.status & '00000100' as boolean) " #nao esta na lixeira
    when 'search'
      # monta parte da query referente a busca textual
      query_search = ''
      search_text.each { |text|
        query_search << " AND " unless query_search.empty? # nao adiciona na 1a vez
        query_search << "     (subject  ilike '%#{text}%' or
                               content  ilike '%#{text}%' or
                               (select users.name from users inner join user_messages
                                ON users.id = user_messages.user_id
                                where user_messages.message_id = m.id
                                and cast(user_messages.status & '00000001' as boolean)) ilike '%#{text}%' or
                               ml.title ilike '%#{text}%')"
      }
      query_messages += " and ( #{query_search} )"
    end
    query_messages += " order by send_date desc "

    msg = Message.find_by_sql(query_messages)
   
    return msg.paginate :page => page, :per_page => Record_Per_Page
  end

  def unread_inbox(userid, tag=nil)
    query_messages = "select count(m.id)n

      from messages m
        inner join user_messages usm on m.id = usm.message_id
        inner join users u on usm.user_id=u.id
        left join user_message_labels uml on usm.id = uml.user_message_id
        left join message_labels ml on uml.message_label_id = ml.id
        
      where
        usm.user_id = #{userid}
        and NOT cast( usm.status & '00000001' as boolean)
        and NOT cast( usm.status & '00000010' as boolean)
        and NOT cast( usm.status & '00000100' as boolean)"

    if !tag.nil?
      query_messages += " and ml.title = '#{tag}' "
    end

    total = Message.find_by_sql(query_messages)

    return total[0].n.to_i 
  end

  #chamada depois de get_contacts para montar os contatos atualizados
  def show_contacts_updated
    text = ""
    if !@all_contacts.nil?
        @all_contacts.each do |c|
            text << "<a class='message_link' href=javascript:add_receiver('#{c.email}')>" << c.name << " [" << c.email << "]</a><br/>"
        end
    end
    if !@responsibles.nil?
        @responsibles.each do |r|
            text << "<a class='message_link' href=javascript:add_receiver('#{r.email}')>" << r.username << " [" << r.email << "]</a><br/>"
        end
    end
    if !@participants.nil?
        @participants.each do |p|
            text << "<a class='message_link' href=javascript:add_receiver('#{p.email}')>" << p.username << " [" << p.email << "]</a><br/>"
        end
    end
    return text
  end

  # retorna (1) usuario que enviou a msg
  def get_sender(message_id)
    return User.find(:first,
          :joins => "INNER JOIN user_messages ON users.id = user_messages.user_id",
          :conditions => "user_messages.message_id = #{message_id} and cast( user_messages.status & '00000001' as boolean)")
  end

end
