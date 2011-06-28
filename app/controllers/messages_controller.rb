class MessagesController < ApplicationController

  include MessagesHelper
  include CurriculumUnitsHelper
  include MysolarHelper
  
  before_filter :require_user
  before_filter :message_data
  before_filter :get_contacts, :only => [:new, :reply]

  #load_and_authorize_resource

  def index
    #recebe tipo de msg a ser consultada
    @type = params[:type]
    if @type.nil?
      @type = "index"
    end

    page = params[:page].nil? ? "1" : params[:page]

    # retorna mensagens
    @messages = return_messages(current_user.id, @type, @message_tag, page)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
    end
  end

  def new
    #recebe nil quando esta em pagina de leitura/edicao de msg
    @type = nil
    @show_message = 'new'
    get_contacts
  end

  def send_message
    if !params[:to].nil? && !params[:newMessageTextBox].nil?
      to = params[:to]
      subject = params[:subject]
      message = params[:newMessageTextBox]
      #from = current_user

      #grava mensagem
      new_message = Message.new :subject => subject, :content => message, :send_date => DateTime.now

      if new_message.save

        #salva remetente
        #status=3 => 00000011 {origem, lida, nao_excluida}
        sender_message = UserMessage.new :message_id => new_message.id, :user_id => current_user.id, :status => 3
        sender_message.save

        #apenas usuarios que sao cadastrados no ambiente; se algum destinarario nao eh, nao envia...
        real_receivers = ""

        #troca ";" por "," para split e envio
        individual_to.gsub(";", ",")
        
        #salva os destinatarios
        individual_to = to.split(",").map{|r|r.strip}

        individual_to.each {|r|
          r_user = User.find_by_email(r)
          if !r_user.nil?
            real_receivers << ", " unless real_receivers.empty?
            real_receivers << r_user.email
            #status=0 {nao_origem, nao_lida, nao_excluida}
            receiver_message = UserMessage.new :message_id => new_message.id, :user_id => r_user.id, :status => 0
            receiver_message.save

            # ****************************
            # FALTA - se for de unidade curricular, gravar labels...
            # ****************************
          end
          }

        #envia email apenas uma vez
        Notifier.deliver_send_mail(real_receivers, subject, message) #, from = nil
      end
      
      redirect_to :action => 'index', :type => 'outbox'
    end
  end

  def show
    if !params[:id].nil?
      message_id = params[:id]

      if has_permission(message_id)
        @message = Message.find(message_id)
        @sender  = get_sender(message_id)
        @recipients  = get_recipients(message_id)
        @files = get_files(message_id)
        
        mark_as_read(message_id)

        @show_message = 'show'
      else
        flash[:error] = t(:no_permission)
        redirect_to :action => "index"
      end
    end
  end

  def reply
    #id da msg
    id = params[:id]

    #recebe nil quando esta em pagina de leitura/edicao de msg
    @type = nil
    @show_message = 'reply'
  end

  # marca mensagem(ns) como lida(s)
  def mark_as_read(message_id)
    # busca mensagem para esse usuario
    message_user = UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).first(1)

    if !message_user.nil?
      # pra zerar (marcar como nao lida) E logico:  & 0b11111101
      # pra setar 1 (marcar como lida) OU logico:   | 0b00000010
      logical_comparison = 0b00000010

      status = message_user[0].status.to_i

      message_user[0].status = status | logical_comparison
      message_user[0].save

      # atualiza qtde de msgs nao lidas
      @unread = unread_inbox(current_user.id, @message_tag)
    end
  end

  # marca mensagem(ns) como nao lida(s)
  def mark_as_unread(message_id)
    # busca mensagem para esse usuario
    message_user = UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).first(1)

    if !message_user.nil?
      # pra zerar (marcar como nao lida) E logico:  & 0b11111101
      # pra setar 1 (marcar como lida) OU logico:   | 0b00000010
      logical_comparison = 0b11111101

      status = message_user[0].status.to_i

      message_user[0].status = status & logical_comparison
      message_user[0].save

      # atualiza qtde de msgs nao lidas
      @unread = unread_inbox(current_user.id, @message_tag)
    end
  end

  # marca mensagem(ns) como lixo
  def mark_as_trash(message_id)
    # busca mensagem para esse usuario
    message_user = UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).first(1)

    if !message_user.nil?
      # pra setar 1 (marcar como excluida) OU logico:   | 0b00000100
      logical_comparison = 0b00000100

      status = message_user[0].status.to_i

      message_user[0].status = status | logical_comparison
      message_user[0].save
    end
  end

  # contatos para montagem da tela
  def get_contacts
    #unidades curriculares do usuario logado
    @curriculum_units_user = load_curriculum_unit_data

    # pegando id da sessao - unidade curricular aberta
    id = session[:opened_tabs][session[:active_tab]]["id"]

    curriculum_unit_id = params[:curriculum_unit_id]
    if curriculum_unit_id.nil?
      curriculum_unit_id = id
    end

    curriculum_unit_name = params[:curriculum_unit_name]

    #unidade curricular ativa ou home ("")
    if curriculum_unit_id == id
      @curriculum_units_name = (session[:opened_tabs][session[:active_tab]]["type"] == Tab_Type_Home) ? "" : session[:active_tab]
    else
      @curriculum_units_name = curriculum_unit_name
    end

    offer = Offer.find_by_curriculum_unit_id(curriculum_unit_id)
    offer_id = offer.id unless offer.nil?

    group = Group.find_by_offer_id(offer)
    group_id = group.id unless group.nil?

    @all_contacts = nil
    @participants = nil
    @responsibles = nil

    # se esta com unidade curricular aberta
    if id != "" || group_id != "" || offer_id != ""
      @participants = class_participants curriculum_unit_id, false, offer_id, group_id
      @responsibles = class_participants curriculum_unit_id, true, offer_id, group_id
    else
      @all_contacts = nil
    end

    text = show_contacts_updated
    return text
    
  end

  # retorna (1) usuario que enviou a msg
  def get_sender(message_id)
    return User.find(:first, 
          :joins => "INNER JOIN user_messages ON users.id = user_messages.user_id",
          :conditions => "user_messages.message_id = #{message_id} and cast( user_messages.status & '00000001' as boolean)")
  end

  # retorna (1 a varios) destinatarios
  def get_recipients(message_id)
    return User.find(:all,
          :joins => "INNER JOIN user_messages ON users.id = user_messages.user_id",
          :select => "users.*",
          :conditions => "user_messages.message_id = #{message_id} and NOT cast( user_messages.status & '00000001' as boolean)")
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

  def message_data
    # verifica aba aberta, se Home ou se aba de unidade curricular
    # se Home, traz todas; senao, traz com filtro da unidade curricular
    if session[:opened_tabs][session[:active_tab]]["type"] != Tab_Type_Home
      @message_tag = session[:active_tab]
    else
      @message_tag = nil
    end

    # qtde de msgs nao lidas
    @unread = unread_inbox(current_user.id, @message_tag)
  end

end
