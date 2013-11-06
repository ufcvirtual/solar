module MessagesHelper

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
        text << "<span id='u#{p.id}'><a class='message_link' href=javascript:message_add_receiver('u#{p.id}','#{URI.escape(p.username)}','#{p.email}')>" << p.username << " [" << p.email << "]</a><br/></span>"
      end
    end

    return text
  end

  def has_permission(message_id)
    not UserMessage.where(user_id: current_user.id, message_id: message_id).nil?
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

  #################################

  def copy_file(origin, destiny, all_files_destiny, flag_copy = true)
    origin  = MessagesController::Path_Message_Files.join(origin)
    destiny = MessagesController::Path_Message_Files.join(destiny)

    # copia fisicamente arquivo do anexo original
    FileUtils.cp origin, destiny if flag_copy

    [all_files_destiny, destiny].delete_if {|x| x == '' }.compact.join(';')
  end

  def change_message_status(message_id, new_status = 'read', box = 'inbox')
    # pra marcar como nao lida (zerar 2o bit) realiza E logico:   & 0b11111101
    # pra marcar como lida (1 no 2o bit)      realiza  OU logico: | 0b00000010
    # pra marcar como excluida (1 no 3o bit) realiza  OU logico: | 0b00000100
    # pra marcar como nao exc (zerar 3o bit) realiza E logico:   & 0b11111011   ***** A FAZER: mover para inbox *****

    query = ["message_id = #{message_id} AND user_id = #{current_user.id}"]
    query << case box
    when "inbox" # NOT (trashbox, outbox)
      "NOT cast(user_messages.status & #{Message_Filter_Sender} as boolean) AND NOT cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    when "outbox"
      "cast(user_messages.status & #{Message_Filter_Sender} as boolean)"
    when "trashbox"
      "cast(user_messages.status & #{Message_Filter_Trash} as boolean)"
    end

    user_message = UserMessage.where(query.join(" AND ")).first
    raise CanCan::AccessDenied unless user_message

    status = user_message.status.to_i
    user_message.status = case new_status
    when "read"
      status | Message_Filter_Read
    when "unread"
      status & Message_Filter_Unread
    when "trash"
      status | Message_Filter_Trash
    when "restore"
      status & Message_Filter_Restore
    end

    user_message.save
  end

end
