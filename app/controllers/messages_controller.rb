class MessagesController < ApplicationController

  include MessagesHelper
  include CurriculumUnitsHelper
  include MysolarHelper
  
  before_filter :require_user
  before_filter :message_data
  before_filter :get_curriculum_units
  before_filter :prepare_for_pagination, :only => [:index]

  # nao precisa usar load_and_authorize_resource pq todos tem acesso

  # listagem de mensagens (entrada, enviados, lixeira)
  def index
    #recebe tipo de msg a ser consultada
    @type = params[:type]

    @search_text = params[:search].nil? ? "" : params[:search]
    @type = 'search' unless @search_text.empty?

    if @type.nil?
      @type = "index"
    end

    # retorna mensagens
    @messages = return_messages(current_user.id, @type, @message_tag, @search_text.split(" "))
  end

  # edicao de mensagem (nova, responder, encaminhar)
  def new
    #recebe nil quando esta em pagina de leitura/edicao de msg
    @type = nil

    @search_text = params[:search].nil? ? "" : params[:search]

    @show_message = 'new'
    get_contacts

    @target  = ''
    @subject = ''
    @original_message = ''
    @target_html = ''

    if !params[:id].nil?
      @original_message_id = params[:id]

      get_message_data(@original_message_id)

      @subject = @message.subject
      
      # remetente
      sender = get_sender(@original_message_id)

      # arquivos
      @files = get_files(@original_message_id)

      # destinatarios
      all_recipients = ''
      all_recipients_name = ''
      all_recipients_html = ''
      get_recipients(@original_message_id).each { |r|
        all_recipients = all_recipients << r.email << ', ' unless r.email == current_user.email
        all_recipients_html = all_recipients_html << "<span onclick='$(this).remove()' class='message_recipient_box' >#{r.email}, </span>" unless r.email == current_user.email
        # apenas para identificacao do email - informa todos, inclusive o logado
        all_recipients_name = all_recipients_name << r.name << " [" << r.email << "], "
      }

      # identificacao da mensagem original para juntar ao texto
      message_header =  t(:message_from) << ": " << sender.name << " [" << sender.email << "]<br/>"
      message_header << t(:message_date) << ": " << @message.send_date.to_s << "<br/>"
      message_header << t(:message_subject) << ": " << @subject << "<br/>"
      message_header << t(:message_to) << ": " << all_recipients_name << "<br/>"

      @original_message = "<p>&nbsp;</p><p>&nbsp;</p><hr/>" << message_header << "<p>&nbsp;</p>" << @message.content

      if !params[:target].nil?
        target = params[:target]

        # encaminhando
        if target.empty?
          @subject = t(:message_subject_route) << @subject
        else
          # respondendo          
          @subject = t(:message_subject_reply) << @subject
          
          # so adiciona usuarios diferentes do logado (nao manda msg pra si, a menos q escolhar abertamente depois)
          @target = sender.email << ', ' unless sender.id == current_user.id
          @target_html = "<span onclick='$(this).remove()' class='message_recipient_box' >#{@target}</span>" unless sender.id == current_user.id
          
          # destinatarios
          if target == 'all'
            @target = @target << all_recipients
            @target_html = @target_html << all_recipients_html
          end
        end
      end
    end

  end

  # exibe mensagem para leitura apenas
  def show
    if !params[:id].nil?
      message_id = params[:id]
      @show_message = 'show'
      get_message_data(message_id)
    end
    @search_text = params[:search].nil? ? "" : params[:search]
  end
  
  # na verdade, muda status para apagado - pode receber um id ou varios separados por $
  def destroy
    id = params[:id]

    if id != ""
      #eh apenas um id
      if id.index("$").nil?
        if has_permission(id)
          change_message_status(id,'trash')
        end
      else
        #mais de um id
        deleted_id = id.split("$")
        deleted_id.each { |i|
          if has_permission(i)
            change_message_status(i,'trash')
          end
        }
      end
    end

    type = params[:type]

    search_text = params[:search].nil? ? "" : params[:search]

    if type.nil?
      type = 'inbox'
    end
    redirect_to :action => 'index', :type => type, :search => search_text
  end

  # muda status para lido/nao lido - pode receber um id ou varios separados por $
  def change_indicator_reading
    id = params[:id]
    new_status = params[:new_status]

    if id != ""
      #eh apenas um id
      if id.index("$").nil?
        if has_permission(id)
          if new_status == "read"
            change_message_status(id,'read')
          else
            change_message_status(id,'unread')
          end
        end
      else
        #mais de um id
        deleted_id = id.split("$")
        deleted_id.each { |i|
          if has_permission(i)
            if new_status == "read"
              change_message_status(i,'read')
            else
              change_message_status(i,'unread')
            end
          end
        }
      end
    end

    type = params[:type]

    search_text = params[:search].nil? ? "" : params[:search]

    if type.nil?
      redirect_to :action => 'show', :id => id, :search => search_text
    else
      redirect_to :action => 'index', :type => type, :search => search_text
    end    
  end

=begin SO PARA TESTE
  def send_message
    if !params[:to].nil? && !params[:to].empty?
      to = params[:to]
      subject = params[:subject]
      message = params[:newMessageTextBox]

      #apenas usuarios que sao cadastrados no ambiente; se algum destinarario nao eh, nao envia...
      real_receivers = ""

      #troca ";" por "," para split e envio para destinatarios
      to.gsub(";", ",")

      #divide destinatarios
      individual_to = to.split(",").map{|r|r.strip}

      update_tab_values
      label_name = get_label_name(@curriculum_unit_id, @offer_id, @group_id)

      #informacoes do usuario atual para identificacao na msg
      atual_user = User.find(current_user.id)
      message_header = "<b>" + t(:message_header) + atual_user.name + " [" + atual_user.email + "]</b><br/>"
      if label_name != ""
        message_header << "[" + label_name + "]<br/>"
      end
      message_header << "________________________________________________________________________<br/><br/>"

      #":requires_new => true" permite rollback

          #salva nova mensagem
          new_message = Message.new :subject => subject, :content => message, :send_date => DateTime.now
          new_message.save!

          original_message_id = params[:id]

          # ******************************************************************************************
          # verificar se tem permissao para esse original_message_id *********************************
          # para cada arquivo, copiar fisicamente                    *********************************
          # ******************************************************************************************

          #recupera arquivos da mensagem original, caso esteja encaminhando ou respondendo
          unless original_message_id.nil?
            files = get_files(original_message_id)
            unless files.nil?
              files.each do |f|
                message_file = MessageFile.new
                message_file[:message_file_name] = f.message_file_name
                message_file[:message_content_type] = f.message_content_type
                message_file[:message_file_size] = f.message_file_size
                message_file[:original_name] = f.original_name # remover esse campo daqui e da migrate
                message_file[:message_id] = new_message.id
                message_file.save!
              end
            end
          end

          #recupera os arquivos anexados
          unless params[:attachment].nil?
            params[:attachment].each do |file|
              message_file = MessageFile.new Hash["message", file[1]]
              message_file[:original_name] = "" # remover esse campo daqui e da migrate
              message_file[:message_id] = new_message.id
              message_file.save!
            end
          end

    end
  end
=end

  def send_message
    if !params[:to].nil? && !params[:to].empty?
      to = params[:to]
      subject = params[:subject]
      message = params[:newMessageTextBox]

      #apenas usuarios que sao cadastrados no ambiente; se algum destinarario nao eh, nao envia...
      real_receivers = ""

      #troca ";" por "," para split e envio para destinatarios
      to.gsub(";", ",")

      #divide destinatarios
      individual_to = to.split(",").map{|r|r.strip}

      update_tab_values
      label_name = get_label_name(@curriculum_unit_id, @offer_id, @group_id)
      
      #informacoes do usuario atual para identificacao na msg
      atual_user = User.find(current_user.id)
      message_header = "<b>" + t(:message_header) + atual_user.name + " [" + atual_user.email + "]</b><br/>"      
      if label_name != ""
        message_header << "[" + label_name + "]<br/>"
      end
      message_header << "________________________________________________________________________<br/><br/>"

      #":requires_new => true" permite rollback
      Message.transaction do
        begin
          #salva nova mensagem
          new_message = Message.new :subject => subject, :content => message, :send_date => DateTime.now
          new_message.save!

          original_message_id = params[:id]

          # ******************************************************************************************
          # verificar se tem permissao para esse original_message_id *********************************
          # para cada arquivo, copiar fisicamente                    *********************************
          # talvez: apagar arquivo caso haja rollback                *********************************
          # ******************************************************************************************

          #recupera arquivos da mensagem original, caso esteja encaminhando ou respondendo
          unless original_message_id.nil?
            files = get_files(original_message_id)
            unless files.nil?
              files.each do |f|
                message_file = MessageFile.new
                message_file[:message_file_name] = f.message_file_name
                message_file[:message_content_type] = f.message_content_type
                message_file[:message_file_size] = f.message_file_size
                message_file[:original_name] = f.original_name # remover esse campo daqui e da migrate
                message_file[:message_id] = new_message.id
                message_file.save!
              end
            end
          end

          #recupera os arquivos anexados
          unless params[:attachment].nil?
            params[:attachment].each do |file|
              message_file = MessageFile.new Hash["message", file[1]]
              message_file[:original_name] = "" # remover esse campo daqui e da migrate
              message_file[:message_id] = new_message.id
              message_file.save!
            end
          end

          #salva dados de remetente
          UserMessage.transaction(:requires_new => true) do
            #status=3 => 00000011 {origem, lida, nao_excluida}
            sender_message = UserMessage.new :message_id => new_message.id, :user_id => current_user.id, :status => 3
            sender_message.save!

            if label_name != ""
              message_label = MessageLabel.find_all_by_title_and_user_id(label_name,current_user.id).first
              #se precisa mas nao existe no banco, cria
              if message_label.nil?
                MessageLabel.transaction(:requires_new => true) do
                  message_label = MessageLabel.new :user_id => current_user.id, :title => label_name, :label_system => true
                  message_label.save!
                end
              end

              #associa label do remetente
              UserMessageLabel.transaction(:requires_new => true)do
                UserMessageLabel.create! :user_message_id => sender_message.id, :message_label_id => message_label.id
              end
            end
          end

          #para salvar destinatarios individualmente - pegar o id
          UserMessage.transaction(:requires_new => true) do
            individual_to.each {|r|
              r_user = User.find_by_email(r)

              if !r_user.nil?
                real_receivers << ", " unless real_receivers.empty?
                real_receivers << r_user.email

                #status=0 {nao_origem, nao_lida, nao_excluida}
                receiver_message = UserMessage.new :message_id => new_message.id, :user_id => r_user.id, :status => 0
                receiver_message.save!

                # se for de unidade curricular, grava user_message_labels e message_labels do usuario (se nao existir)...
                if label_name != ""
                  message_label = MessageLabel.find_all_by_title_and_user_id(label_name,r_user.id).first
                  #se precisa mas nao existe no banco, cria
                  if message_label.nil?
                    MessageLabel.transaction(:requires_new => true) do
                      message_label = MessageLabel.new :user_id => r_user.id, :title => label_name
                      message_label.save!
                    end
                  end

                  #associa label do destinatario
                  UserMessageLabel.transaction(:requires_new => true)do
                    UserMessageLabel.create! :user_message_id => receiver_message.id, :message_label_id => message_label.id
                  end
                end
              end
            }
          end

        rescue
          flash[:notice] = t(:message_send_error)
          # efetua rollback
          raise ActiveRecord::Rollback
        else
          if real_receivers.empty?
            flash[:notice] = t(:message_send_error_no_receiver)
          else
            flash[:notice] = t(:message_send_ok)
            # envia email apenas uma vez, em caso de sucesso da gravacao no banco
            Notifier.deliver_send_mail(real_receivers, subject, message_header + message) unless real_receivers.empty? #, from = nil            
          end
        end
      end

      redirect_to :action => 'index', :type => 'outbox'
    else
      redirect_to :action => 'new'
    end
  end

  #download de arquivo anexo
  def download_message_file
    file_id = params[:idFile]
    file_ = MessageFile.find(file_id)
    filename = file_.message_file_name

    prefix_file = file_.id # id da tabela discussion_post_file para diferenciar os arquivos
    path_file = "#{::Rails.root.to_s}/media/message/"

    redirect_error = {:action => 'show', :id => params[:id], :idFile => file_id}
    
    # recupera arquivo
    download_file(redirect_error, path_file, filename, prefix_file)
  end

  # retorna a label a ser usada na mensagem indicando disciplina, semestre e periodo
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

  # metodo chamado por ajax para atualizar contatos
  def ajax_get_contacts
    get_contacts
    render :layout => false
  end

  # unidades curriculares do usuario logado
  def get_curriculum_units    
    @curriculum_units_user = load_curriculum_unit_data
  end
  
  # retorna (1 a varios) destinatarios
  def get_recipients(message_id)
    return User.find(:all,
      :joins => "INNER JOIN user_messages ON users.id = user_messages.user_id",
      :select => "users.*",
      :conditions => "user_messages.message_id = #{message_id} and NOT cast( user_messages.status & '#{Message_Filter_Sender.to_s(2)}' as boolean)")
  end

  # retorna (0 a varios) arquivos de anexo
  def get_files(message_id)
    return MessageFile.find :all, :conditions => ["message_id = ?", message_id]
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

  private

  # verifica aba aberta, se Home ou se aba de unidade curricular
  # se Home, traz todas; senao, traz com filtro da unidade curricular
  def message_data    
    if session[:opened_tabs][session[:active_tab]]["type"] != Tab_Type_Home
      group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
      offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
      curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]

      @message_tag = get_label_name(curriculum_unit_id, offer_id, group_id)
    else
      @message_tag = nil
    end

    # qtde de msgs nao lidas
    @unread = unread_inbox(current_user.id, @message_tag)
  end

  def update_tab_values
    # pegando id da sessao - unidade curricular aberta
    id = session[:opened_tabs][session[:active_tab]]["id"]

    @curriculum_unit_id = nil
    @offer_id = nil
    @group_id = nil

    if !params[:data].nil?
      data = params[:data].split(";").map{|r|r.strip}

      @curriculum_unit_id = data[0]
      @offer_id = data[1]
      @group_id = data[2]
    else
      if session[:opened_tabs][session[:active_tab]]["type"] != Tab_Type_Home
        @curriculum_unit_id = id

        #offer = Offer.find_by_curriculum_unit_id(id)
        @offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

        #group = Group.find_by_offer_id(@offer_id)
        @group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
      end
    end
  end

  # contatos para montagem da tela
  def get_contacts
    # pegando id da sessao - unidade curricular aberta
    id = session[:opened_tabs][session[:active_tab]]["id"]
    update_tab_values

    #unidade curricular ativa ou home ("")
    if @curriculum_unit_id == id
      @curriculum_units_name = (session[:opened_tabs][session[:active_tab]]["type"] == Tab_Type_Home) ? "" : session[:active_tab]
    else
      @curriculum_units_name = CurriculumUnit.find(@curriculum_unit_id).name unless @curriculum_unit_id.nil?
    end

    @all_contacts = nil
    @participants = nil
    @responsibles = nil

    # se esta com unidade curricular aberta
    if !@curriculum_unit_id.nil? || !@group_id.nil? || !@offer_id.nil?
      @participants = class_participants @curriculum_unit_id, false, @offer_id, @group_id
      @responsibles = class_participants @curriculum_unit_id, true,  @offer_id, @group_id
    else
      @all_contacts = User.order("name").find(:all, :joins => :user_contacts,
        :conditions => {:user_contacts => {:user_id => current_user.id}} )
    end

    @contacts = show_contacts_updated   
    return @contacts
  end

  # marca mensagem(ns) como lida (read), nao lida (unread), excluida (trash)
  def change_message_status(message_id, new_status = 'read')
    # busca mensagem para esse usuario

    UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).all? { |m|
      # pra marcar como nao lida (zerar 2o bit) realiza E logico:   & 0b11111101
      # pra marcar como lida (1 no 2o bit)      realiza  OU logico: | 0b00000010
      # pra marcar como excluida) (1 no 3o bit) realiza  OU logico: | 0b00000100

      status = m.status.to_i

      case new_status
      when 'read'
        m.status = status | Message_Filter_Read
      when 'unread'
        m.status = status & Message_Filter_Unread
      when 'trash'
        m.status = status | Message_Filter_Trash
      end

      m.save

      # atualiza qtde de msgs nao lidas
      @unread = unread_inbox(current_user.id, @message_tag)
    }

  end

  # retorna dados da mensagem passada (mensagem, remetente, destinatarios, arquivos) e marca como lida
  # se não tem permissao, redireciona
  def get_message_data(message_id)
    if has_permission(message_id)
      @message = Message.find(message_id)
      @sender  = get_sender(message_id)
      @recipients  = get_recipients(message_id)
      @files = get_files(message_id)

      change_message_status(message_id,'read')
    else
      @show_message = ''
      flash[:error] = t(:no_permission)
      redirect_to :action => "index"
    end
  end

end
