module V1::Messages

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

    unless status==1
      user_message.api = true
      user_message.save
    end
  end

  def read_message(message)
    user_message = message.user_messages.where(user_id: current_user.id).where("NOT(cast(user_messages.status & #{Message_Filter_Sender} as boolean))").first
    raise CanCan::AccessDenied unless user_message
    user_message.status = (user_message.status | Message_Filter_Read)
    unless status==1
      user_message.api = true
      user_message.save
    end
  end

  def new_msg_template(at, msg)
    system_label = !at.nil?

    %{
      <b>#{I18n.t(:mail_header, scope: :messages)} #{current_user.to_msg[:resume]}</b><br/>
      #{msg.labels(current_user.id, system_label) if system_label}<br/>
      ________________________________________________________________________<br/><br/>
      #{msg.content}
    }
  end

end
