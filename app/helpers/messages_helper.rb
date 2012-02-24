module MessagesHelper

  def return_messages (userid, type='index', tag=nil, search_text='')

    query_fields = "
    SELECT DISTINCT ON (m.id, m.send_date)
           m.*, usm.user_id, u.name, u.nick, ml.title AS label,
           (SELECT count(message_file_name) FROM message_files WHERE message_id = m.id)  AS has_attachment,
           cast( usm.status & '#{Message_Filter_Sender.to_s(2)}' as boolean)             AS was_sent,
           cast( usm.status & '#{Message_Filter_Read.to_s(2)}' as boolean)               AS was_read,
           (SELECT users.name
              FROM users
              JOIN user_messages ON users.id = user_messages.user_id
             WHERE user_messages.message_id = m.id
               AND cast( user_messages.status & '#{Message_Filter_Sender.to_s(2)}' as boolean)
           ) AS sender"

    query_messages = "
    FROM messages                 AS m
        JOIN user_messages        AS usm  ON m.id = usm.message_id
   LEFT JOIN message_files        AS f    ON m.id = f.message_id
        JOIN users                AS u    ON usm.user_id=u.id
   LEFT JOIN user_message_labels  AS uml  ON usm.id = uml.user_message_id
   LEFT JOIN message_labels       AS ml   ON uml.message_label_id = ml.id
       WHERE usm.user_id = #{userid}"  #filtra por usuario

    # formato: 2011.1|FOR|Física I
    # monta label para pesquisa que inclua mensagens enviadas por turma/oferta
    if !tag.nil?
      tag_slice = tag.split("|")
      case tag_slice.count()
      when 3
        #se label foi criada por aluno ou outro perfil vinculado a turma, possui 3 partes
        query_label1 = tag_slice[0] << "|" << tag_slice[2]
        query_messages += " and ( ml.title = '#{query_label1}' or ml.title = '#{tag}' )"
      when 2
        #se label foi criada por prof ou outro perfil vinculado a oferta, possui 2 partes
        query_label1 = tag_slice[0] << "|%|" << tag_slice[1]
        query_messages += " and ( ml.title ilike '#{query_label1}' or ml.title = '#{tag}' )"
      else
        query_messages += " and ( ml.title = '#{tag}' )"
      end
    end
    
    case type
    when 'trashbox'
      query_messages += " AND cast( usm.status & '#{Message_Filter_Trash.to_s(2)}' AS boolean) "     #filtra se eh excluida
    when 'index'
      query_messages += " AND NOT cast( usm.status & '#{Message_Filter_Sender.to_s(2)}' AS boolean) " #filtra se nao eh origem (eh destino)
      query_messages += " AND NOT cast( usm.status & '#{Message_Filter_Trash.to_s(2)}' AS boolean) " #nao esta na lixeira
    when 'outbox'
      query_messages += " AND     cast( usm.status & '#{Message_Filter_Sender.to_s(2)}' AS boolean) " #filtra se eh origem (default)
      query_messages += " AND NOT cast( usm.status & '#{Message_Filter_Trash.to_s(2)}' AS boolean) " #nao esta na lixeira
    when 'portlet'
      query_messages += " AND NOT cast( usm.status & '#{Message_Filter_Sender.to_s(2)}' AS boolean) " #filtra se nao eh origem (eh destino)
      query_messages += " AND NOT cast( usm.status & '#{Message_Filter_Read.to_s(2)}' AS boolean) "   #nao lida
      query_messages += " AND NOT cast( usm.status & '#{Message_Filter_Trash.to_s(2)}' AS boolean) "  #nao esta na lixeira
      
    when 'search'
      # monta parte da query referente a busca textual
      query_search = ''
      query_search << " NOT cast( usm.status & '#{Message_Filter_Trash.to_s(2)}' AS boolean) "   #nao esta na lixeira
      search_text.each { |text|
        query_search << " AND " unless query_search.empty? # nao adiciona na 1a vez
        query_search << "     (subject  ilike '%#{text}%' or
                               content  ilike '%#{text}%' or "

        begin
          # pega formato da data a usar na query de acordo com idioma atual (ex: dd mm yyyy)
          # date_format = I18n.t :query_format, :scope => 'date'
          
          # coloca data no formato do idioma atual - converte sempre em dd mm yyyy... (?)
          # entrando 08/02/2011:
          #     em ingles - text.to_date = 2011-02-08 e d = 02/08/2011
          #     em port   - text.to_date = 2011-02-08 e d = 08/02/2011
          if text.length == 5
            date_text = text + "/" + Time.now.year.to_s
          else
            date_text = text
          end
          d = I18n.l(date_text.to_date, :format => :default).to_s
          query_date = " m.send_date::date = to_date('#{d}','dd mm yyyy') or"
        rescue
          query_date = ""
        end

        query_search << query_date
        query_search << "     (select users.name from users inner join user_messages
                                ON users.id = user_messages.user_id
                                where user_messages.message_id = m.id
                                and cast(user_messages.status & '#{Message_Filter_Sender.to_s(2)}' as boolean)) ilike '%#{text}%' or
                                ml.title ilike '%#{text}%')"
      }
      query_messages += " and ( #{query_search} )"

    end
    query_order = " ORDER BY send_date desc, m.id "

    query_all = query_fields << query_messages << query_order

    # retorna total de mensagens
    query_count = " select count(distinct m.id) total " << query_messages

    @messages_count = ActiveRecord::Base.connection.execute(query_count)[0]["total"]

    if (@messages_count.to_i > 0)
      # retorna mensagens paginadas
      return Message.paginate_by_sql(query_all, {:per_page => Rails.application.config.items_per_page, :page => @current_page})
    else
      return nil
    end
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
        and NOT cast( usm.status & '#{Message_Filter_Sender.to_s(2)}' as boolean) 
        and NOT cast( usm.status & '#{Message_Filter_Read.to_s(2)}' as boolean)
        and NOT cast( usm.status & '#{Message_Filter_Trash.to_s(2)}' as boolean)"

    #formato: 2011.1|FOR|Física I
    #monta label para pesquisa que inclua mensagens enviadas por turma/oferta
    if !tag.nil?
      tag_slice = tag.split("|")
      case tag_slice.count()
      when 3
        #se label foi criada por aluno ou outro perfil vinculado a turma, possui 3 partes
        query_label1 = tag_slice[0] << "|" << tag_slice[2]
        query_messages += " and ( ml.title = '#{query_label1}' or ml.title = '#{tag}' )"
      when 2
        #se label foi criada por prof ou outro perfil vinculado a oferta, possui 2 partes
        query_label1 = tag_slice[0] << "|%|" << tag_slice[1]
        query_messages += " and ( ml.title ilike '#{query_label1}' or ml.title = '#{tag}' )"
      else
        query_messages += " and ( ml.title = '#{tag}' )"
      end
    end

    total = Message.find_by_sql(query_messages)
    return total[0].n.to_i 
  end

  ##
  # Recupera label
  ##
  def get_label_name(group, offer, c_unit)

    #formato: 2011.1|FOR|Física I
    label_name = ''
    label_name << offer.semester.slice(0..5) << '|' if offer.respond_to?('semester')
    label_name << group.code.slice(0..9) << '|' if group.respond_to?('code')
    label_name << c_unit.name.slice(0..15) if c_unit.respond_to?('name')

    return label_name
  end

  #chamada depois de get_contacts para montar os contatos atualizados
  def show_contacts_updated
    text = ""
    if !@all_contacts.nil?
      @all_contacts.each do |c|
        text << "<span id='u#{c.id}'><a class='message_link' href=javascript:add_receiver('u#{c.id}','#{URI.escape(c.name)}','#{c.email}')>" << c.name << " [" << c.email << "]</a><br/></span>"
      end
    end
    if !@responsibles.nil?
      @responsibles.each do |r|
        text << "<span id='u#{r.id}'><a class='message_link' href=javascript:add_receiver('u#{r.id}','#{URI.escape(r.username)}','#{r.email}')>" << r.username << " [" << r.email << "]</a><br/></span>"
      end
    end
    if !@participants.nil?
      @participants.each do |p|
        text << "<span id='u#{p.id}'><a class='message_link' href=javascript:add_receiver('u#{p.id}','#{URI.escape(p.username)}','#{p.email}')>" << p.username << " [" << p.email << "]</a><br/></span>"
      end
    end
    return text
  end

  # retorna (1) usuario que enviou a msg
  def get_sender(message_id)
    return User.find(:first,
      :joins => "INNER JOIN user_messages ON users.id = user_messages.user_id",
      :conditions => "user_messages.message_id = #{message_id} and cast( user_messages.status & '#{Message_Filter_Sender.to_s(2)}' AS boolean)")
  end

  # verifica se usuario logado tem permissao de acessar a mensagem com id passado
  def has_permission(message_id)
    # traz usuarios relacionados a msg - pra verificar permissao de acesso
    user_messages = UserMessage.find_all_by_message_id(message_id)

    # procura usuario logado ente usuarios que podem acessar msg
    search = user_messages.find { |i| i.user_id==current_user.id }

    if search.nil?
      return false
    end
    return true
  end
  
  #Verifica se a messagem foi postada hoje ou não!
  def sent_today?(message_datetime)
    message_datetime === Date.today
  end

end
