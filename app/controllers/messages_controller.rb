class MessagesController < ApplicationController
  include FilesHelper
  include MessagesHelper
  include CurriculumUnitsHelper
  include MysolarHelper

  Path_Message_Files = Rails.root.join('media', 'messages')

  before_filter :prepare_for_group_selection, only: [:index]

  def index
    @box = params[:box] || "inbox"
    @messages = Message.send("user_#{@box}", current_user.id)
                        .paginate(page: params[:page] || 1, per_page: Rails.application.config.items_per_page)
                        .order("send_date DESC")
  end

  # edicao de mensagem (nova, responder, encaminhar)
  def new
    @curriculum_units_user = load_curriculum_unit_data
    @type = nil # recebe nil quando esta em pagina de leitura/edicao de msg
    @search_text = params[:search] || ''
    @show_message = 'new'
    get_contacts

    @target, @subject, @original_message, @target_html  = '', '', '', ''

    if not(params[:id].nil?)
      @original_message_id = params.delete(:id)
      @message = Message.find(@original_message_id)
      @subject = @message.subject
      sender = @message.sent_by
      @files = @message.files

      # destinatarios
      all_recipients, all_recipients_name, all_recipients_html = '', '', ''
      recipients = Message.find(@original_message_id).recipients
      recipients.each { |r|
        all_recipients = [all_recipients, r.name, ' [', r.email, '], '].join unless r.email == current_user.email
        all_jquery = "'#u#{r.id}'"
        all_recipients_html = all_recipients_html << "<span onclick=""$(#{all_jquery}).show();$(this).remove()"" class='message_recipient_box' >#{r.name} [#{r.email}], </span>" unless r.email == current_user.email
        # apenas para identificacao do email - informa todos, inclusive o logado
        all_recipients_name = [all_recipients_name, r.name, " [", r.email, "], "].join
      }

      # identificacao da mensagem original para juntar ao texto
      message_header =  [t(:message_from), ": ", sender.name, " [", sender.email, "]<br/>"].join
      message_header << [t(:message_date), ": ",  "#{l(@message.send_date, :format => :clock)}", "<br/>"].join
      message_header << [t(:message_subject), ": ", @subject, "<br/>"].join
      message_header << [t(:message_to), ": ", all_recipients_name, "<br/>"].join

      @original_message =  ["<p>&nbsp;</p><p>&nbsp;</p><hr/>", message_header, "<p>&nbsp;</p>", @message.content].join

      if not(params[:target].nil?)
        target = params[:target]

        # encaminhando
        if target.empty?
          @subject = t(:message_subject_route) << @subject
        else
          # respondendo
          @subject = t(:message_subject_reply) << @subject
          # so adiciona usuarios diferentes do logado (nao manda msg pra si, a menos q escolhar abertamente depois)
          @target = "#{sender.name} [#{sender.email}], " unless sender.id == current_user.id

          target_jquery = "'#u#{sender.id}'"
          @target_html = "<span onclick=""$(#{target_jquery}).show();$(this).remove()"" class='message_recipient_box' >#{@target}</span>" unless sender.id == current_user.id

          # destinatarios
          if target == 'all'
            @target = @target << all_recipients
            @target_html = @target_html << all_recipients_html
          end
        end
      end
    end
  end

  def send_message
    if params[:to].present?
      to = params[:to]
      subject = params[:subject]
      message = params[:content]

      # apenas usuarios que sao cadastrados no ambiente; se algum destinarario nao eh, nao envia...
      real_receivers = []

      # anexos de mensagem original quando encaminhando ou respondendo mensagem
      all_files_destiny = ""

      # troca ";" por "," para split e envio para destinatarios
      to.gsub(";", ",")

      # divide destinatarios
      individual_to = to.split(",").map{|r|r.strip}

      # update_tab_values

      # retorna label de acordo com disciplina atual
      allocation_tag_id = active_tab[:url][:allocation_tag_id]

      label_name = ''
      unless allocation_tag_id.nil?
        ats = AllocationTag.find_related_ids(allocation_tag_id).join(', ');
        group = AllocationTag.find(allocation_tag_id).group
        offer = AllocationTag.where("id IN (#{ats}) AND offer_id IS NOT NULL").first.try(:offer)
        curriculum_unit = AllocationTag.where("id IN (#{ats}) AND curriculum_unit_id IS NOT NULL").first.try(:curriculum_unit) || CurriculumUnit.find(active_tab[:url][:id])

        label_name = get_label_name(group, offer, curriculum_unit)
      end

      # informacoes do usuario atual para identificacao na msg
      message_header = ["<b>", t(:message_header), current_user.name, " [", current_user.email, "]</b><br/>"].join
      message_header << ["[", label_name, "]<br/>"].join if label_name != ""
      message_header << "________________________________________________________________________<br/><br/>"

      Message.transaction do
        begin
          new_message = Message.create(subject: subject, content: message, send_date: DateTime.now)

          # recupera arquivos da mensagem original, caso esteja encaminhando ou respondendo
          if params[:id].present?
            original_message_id = params[:id]

            # verifica permissao na mensagem original
            if has_permission(original_message_id)

              files = (params[:files].nil? or params[:files].empty?) ? [] : Message.find(original_message_id).files.where(id: params[:files])

              unless files.nil?
                files.each do |f|
                  message_file = MessageFile.create({
                    message_file_name: f.message_file_name,
                    message_content_type: f.message_content_type,
                    message_file_size: f.message_file_size,
                    message_id: new_message.id
                  })
                  origin = [f.id.to_s, f.message_file_name].join('_')
                  destiny = [message_file.id.to_s, f.message_file_name].join('_')

                  all_files_destiny = copy_file(origin, destiny, all_files_destiny, true)
                end # each
              end # unless
            end # if permission
          end # if id

          # recupera os arquivos anexados
          params[:attachment].each do |file|
            message_file = MessageFile.create!({message: file[1], message_id: new_message.id})
            destiny = [message_file.id.to_s, message_file.message_file_name].join('_') # adiciona arquivos de anexo para encaminhar com o email
            all_files_destiny = copy_file("", destiny, all_files_destiny, false)
          end if params[:attachment].present?

          sender_message = UserMessage.create!(message_id: new_message.id, user_id: current_user.id, status: Message_Filter_Sender)
          if label_name != ""
            message_label = MessageLabel.find_by_title_and_user_id(label_name,current_user.id)
            message_label = MessageLabel.create!(user_id: current_user.id, title: label_name, label_system: true) if message_label.nil?

            UserMessageLabel.create!(user_message_id: sender_message.id, message_label_id: message_label.id)
          end

          ## enviando emails para a caixa de entradas dos receptores

          emails = individual_to.reject!{|e| e.empty?}.collect {|r| r.slice(r.index('[')+1..r.index(']')-1)}
          users = User.where(email: emails)
          real_receivers = users.map(&:email)

          ## criando msgs na caixa de entrada de cada usuario
          user_messages = UserMessage.create!(users.map {|user| {message_id: new_message.id, user_id: user.id, status: Message_Filter_Receiver}})

          ## cria-se uma msg label para cada usuario
          if label_name != ''
            user_messages.each do |um|
              message_label = MessageLabel.find_or_create_by_title_and_user_id(label_name, um.user_id)
              UserMessageLabel.create!(user_message_id: um.id, message_label_id: message_label.id)
            end # each
          end # if label name

        rescue Exception => error
          flash[:alert] = error.message.empty? ? t(:message_send_error) : error.message

          # apaga arquivos copiados fisicamente de mensagem original quando ha rollback
          all_files_destiny.split(";").each{ |f| File.delete(f) } unless all_files_destiny.empty?

          raise ActiveRecord::Rollback
        else

          if real_receivers.empty?
            flash[:alert] = t(:message_send_error_no_receiver)
            raise ActiveRecord::Rollback
          else
            flash[:notice] = t(:message_send_ok)
            # envia email apenas uma vez, em caso de sucesso da gravacao no banco
            Notifier.send_mail(real_receivers.join(','), subject, message_header + message, Path_Message_Files.to_s, all_files_destiny.to_s).deliver unless real_receivers.empty? #, from = nil
          end
        end
      end

      redirect_to outbox_messages_path
    else
      redirect_to new_message_path
    end
  end

  def show
    @message = Message.find(params[:id])
    change_message_status(@message.id, "read", @box = params[:box])
  end

  ## [read, unread, trash, restore]
  def update
    begin
      Message.transaction do
        params[:id].split(',').map(&:to_i).each { |i| change_message_status(i, params[:new_status], params[:box]) }
      end
      render json: {success: true}
    rescue
      render json: {success: false}, status: :unprocessable_entity
    end
  end

  def download_files
    file = MessageFile.find(params[:file_id])
    raise CanCan::AccessDenied unless file.original_message.user_has_permission?(current_user.id)

    download_file(inbox_messages_path, file.message.path)
  end

  # metodo chamado por ajax para atualizar contatos
  def ajax_get_contacts
    get_contacts
    render layout: false
  end
end
