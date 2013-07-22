module MessagesHelper

  def return_messages(userid, type='inbox', tag=nil, search_text='')

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
    when 'inbox'
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
    query_count = " select count(distinct m.id) total " << query_messages

    @messages_count = ActiveRecord::Base.connection.execute(query_count)[0]["total"]

    return nil unless (@messages_count.to_i > 0)
    return Message.paginate_by_sql(query_all, {:per_page => Rails.application.config.items_per_page, :page => @current_page})
  end

  def get_label_name(group, offer, c_unit)
    label_name = []
    label_name << offer.semester.name.slice(0..5)  if offer.respond_to?(:semester)
    label_name << group.code.slice(0..9)      if group.respond_to?(:code)
    label_name << c_unit.name.slice(0..15)    if c_unit.respond_to?(:name)

    return label_name.join('|') # formato: 2011.1|FOR|Física I
  end

  #chamada depois de get_contacts para montar os contatos atualizados
  def show_contacts_updated
    text = ""
    
    contacts = @all_contacts.nil? ? [] : @all_contacts
    contacts << @responsibles unless @responsibles.nil?
    contacts << @participants unless @participants.nil?

    if !contacts.nil?
      contacts.flatten.uniq.each do |p|
        text << "<span id='u#{p.id}'><a class='message_link' href=javascript:add_receiver('u#{p.id}','#{URI.escape(p.username)}','#{p.email}')>" << p.username << " [" << p.email << "]</a><br/></span>"
      end
    end

    return text
  end

  def has_permission(message_id)
    not(UserMessage.where(user_id: current_user.id, message_id: message_id).nil?)
  end
  
  def sent_today?(message_datetime)
    message_datetime === Date.today
  end

  def change_message_status(message_id, new_status = 'read', box = 'inbox')
    # pra marcar como nao lida (zerar 2o bit) realiza E logico:   & 0b11111101
    # pra marcar como lida (1 no 2o bit)      realiza  OU logico: | 0b00000010
    # pra marcar como excluida (1 no 3o bit) realiza  OU logico: | 0b00000100
    # pra marcar como nao exc (zerar 3o bit) realiza E logico:   & 0b11111011   ***** A FAZER: mover para inbox *****

    query = ["message_id = #{message_id} AND user_id = #{current_user.id}"]
    query << case box
    when "inbox"
      # NOT (trashbox, outbox)
      "NOT cast(user_messages.status & #{Message_Filter_Sender} as boolean) AND NOT cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    when "outbox"
      "cast(user_messages.status & #{Message_Filter_Sender} as boolean)"
    when "trashbox"
      "cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    end

    # Msgs da box
    message = UserMessage.where(query.join(" AND "))
    message.each { |m|
      status = m.status.to_i
      m.status = case new_status
      when 'read'
        status | Message_Filter_Read
      when 'unread'
        status & Message_Filter_Unread
      when 'trash'
        status | Message_Filter_Trash
      when 'restore'
        status & Message_Filter_Restore
      end

      m.save
    }
  end

  def update_tab_values
    # pegando id da sessao - unidade curricular aberta
    id = active_tab[:url][:id]

    @curriculum_unit_id = nil
    @offer_id = nil
    @group_id = nil

    if !params[:data].nil?
      data = params[:data].split(";").map{|r|r.strip}

      @curriculum_unit_id = data[0]
      @offer_id = data[1]
      @group_id = data[2]
    else
      unless active_tab[:url][:context] == Context_General
        allocation_tag = AllocationTag.find(active_tab[:url][:allocation_tag_id])
        @curriculum_unit_id = id
        @offer_id = allocation_tag.offer_id
        @group_id = allocation_tag.group_id
      end
    end
  end

  # contatos para montagem da tela
  def get_contacts
    # pegando id da sessao - unidade curricular aberta
    id = active_tab[:url][:id]
    update_tab_values

    # unidade curricular ativa ou home ("")
    if @curriculum_unit_id == id
      @curriculum_units_name = (active_tab[:url][:context] == Context_General) ? "" : user_session[:tabs][:active]
    else
      @curriculum_units_name = CurriculumUnit.find(@curriculum_unit_id).name unless @curriculum_unit_id.nil?
    end

    @all_contacts = nil
    @participants = nil
    @responsibles = nil

    # se esta com unidade curricular aberta
    if !@curriculum_unit_id.nil? || !@group_id.nil? || !@offer_id.nil?
      @participants = message_class_participants current_user.id, @curriculum_unit_id, Profile_Type_Class_Responsible, false,  @offer_id, @group_id
      @responsibles = message_class_participants current_user.id, @curriculum_unit_id, Profile_Type_Class_Responsible, true,   @offer_id, @group_id
    else
      @all_contacts = User.order("name").find(:all, :joins => :user_contacts,
        :conditions => {:user_contacts => {:user_id => current_user.id}} )
    end

    @contacts = show_contacts_updated
    return @contacts
  end


  def copy_file(origin, destiny, all_files_destiny, flag_copy = true)
    origin  = MessagesController::Path_Message_Files.join(origin)
    destiny = MessagesController::Path_Message_Files.join(destiny)

    # copia fisicamente arquivo do anexo original
    FileUtils.cp origin, destiny if flag_copy

    [all_files_destiny, destiny].delete_if {|x| x == '' }.compact.join(';')
  end

end
