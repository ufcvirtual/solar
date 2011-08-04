module MessagesHelper

  def return_messages(userid, type='index', tag=nil, search_text)
    query_fields = "select m.*, usm.user_id, f.original_name, u.name, u.nick,ml.title label,
        cast( usm.status & '00000001' as boolean)ehorigem,
        cast( usm.status & '00000010' as boolean)ehlida,
        (select users.name from users inner join user_messages ON users.id = user_messages.user_id
        where user_messages.message_id = m.id and cast( user_messages.status & '00000001' as boolean))sender"

    query_messages = " from messages m
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
      query_search << " NOT cast( usm.status & '00000100' as boolean) "   #nao esta na lixeira
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
    query_order = " order by send_date desc "

    query_all = query_fields << query_messages << query_order

    # retorna total de registros da consulta
    query_count = " select count(*)total " << query_messages
    @messages_count = ActiveRecord::Base.connection.execute(query_count)[0]["total"]

    # retorna mensagens paginadas
    return Message.paginate_by_sql(query_all, {:per_page => Rails.application.config.items_per_page, :page => @current_page})
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
  
  #pegas mensagens nao lidas
  def newest_unread_messages(userid, tag=nil)
    query_messages = "select m.subject, m.send_date, ml.title label,
        (select users.name from users inner join user_messages ON users.id = user_messages.user_id
        where user_messages.message_id = m.id and cast( user_messages.status & '00000001' as boolean))sender
        from messages m
        inner join user_messages usm on m.id = usm.message_id
        left join message_files f on m.id = f.message_id
        inner join users u on usm.user_id=u.id
        left join user_message_labels uml on usm.id = uml.user_message_id
        left join message_labels ml on uml.message_label_id = ml.id
        
      where
        usm.user_id = 1
        AND      not  cast( usm.status & '00000010' as boolean)  
        AND      not  cast( usm.status & '00000001' as boolean)
        AND      not  cast( usm.status & '00000100' as boolean)"

    if !tag.nil?
      query_messages += " and ml.title = '#{tag}' "
    end

    return Message.find_by_sql(query_messages) 
  end
  
  #pega label
  def get_label_name (curriculum_unit_id = nil, offer_id = nil, group_id = nil)
    label_name = ""
    #formato: 2011.1|FOR|Física I
    if !offer_id.nil?
      offer = Offer.find(offer_id)
      label_name << offer.semester.slice(0..5)
    end
    if !group_id.nil?
      group = Group.find(group_id)
      label_name << '|' << group.code.slice(0..9) << '|'
    end
    if !curriculum_unit_id.nil? 
      curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
      label_name << curriculum_unit.name.slice(0..15)
    end
    return label_name
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
