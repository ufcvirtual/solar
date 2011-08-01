class MessagesController < ApplicationController

  include MessagesHelper
  include CurriculumUnitsHelper
  include MysolarHelper
  
  before_filter :require_user
  before_filter :message_data
  before_filter :get_curriculum_units

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
  end

  def new
    #recebe nil quando esta em pagina de leitura/edicao de msg
    @type = nil
    @show_message = 'new'
    get_contacts
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

  # na verdade, muda status para apagado - pode receber um id ou varios separados por $
  def destroy
    id = params[:id]

    if id != ""
      #eh apenas um id
      if id.index("$").nil?
        if has_permission(id)
          mark_as_trash(id)
        end
      else
        #mais de um id
        deleted_id = id.split("$")
        deleted_id.each { |i|
          if has_permission(i)
            mark_as_trash(i)
          end
        }
      end
    end

    type = params[:type]
    if type.nil?
      type = 'inbox'
    end
    redirect_to :action => 'index', :type => type
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
            mark_as_read(id)
          else
            mark_as_unread(id)
          end
        end
      else
        #mais de um id
        deleted_id = id.split("$")
        deleted_id.each { |i|
          if has_permission(i)
            if new_status == "read"
              mark_as_read(i)
            else
              mark_as_unread(i)
            end
          end
        }
      end
    end

    type = params[:type]
    if type.nil?
      redirect_to :action => 'show', :id => id
    else
      redirect_to :action => 'index', :type => type
    end    
  end

  def send_message
    if !params[:to].nil? && !params[:newMessageTextBox].nil?
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
      message = message_header + message

      #":requires_new => true" permite rollback
      Message.transaction do
        begin
          #salva nova mensagem
          new_message = Message.new :subject => subject, :content => message, :send_date => DateTime.now
          new_message.save!

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
            Notifier.deliver_send_mail(real_receivers, subject, message) unless real_receivers.empty? #, from = nil
          end
        end
      end

      redirect_to :action => 'index', :type => 'outbox'
    end
  end

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

  # marca mensagem como lixo
  def mark_as_trash(message_id)
    # busca mensagem para esse usuario
    
    message_user = UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).all? { |m|  
      # pra setar 1 (marcar como excluida) OU logico:   | 0b00000100
      logical_comparison = 0b00000100

      status = m.status.to_i

      m.status = status | logical_comparison
      m.save
    }

  end

  # marca mensagem como lida
  def mark_as_read(message_id)
    # busca mensagem para esse usuario

    message_user = UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).all? { |m|
      # pra zerar (marcar como nao lida) E logico:  & 0b11111101
      # pra setar 1 (marcar como lida) OU logico:   | 0b00000010
      logical_comparison = 0b00000010

      status = m.status.to_i

      m.status = status | logical_comparison
      m.save

      # atualiza qtde de msgs nao lidas
      @unread = unread_inbox(current_user.id, @message_tag)
    }

  end

  # marca mensagem como nao lida
  def mark_as_unread(message_id)
    # busca mensagem para esse usuario
    
    message_user = UserMessage.find_all_by_message_id_and_user_id(message_id,current_user.id).all? { |m|  
      # pra zerar (marcar como nao lida) E logico:  & 0b11111101
      # pra setar 1 (marcar como lida) OU logico:   | 0b00000010
      logical_comparison = 0b11111101

      status = m.status.to_i

      m.status = status & logical_comparison
      m.save

      # atualiza qtde de msgs nao lidas
      @unread = unread_inbox(current_user.id, @message_tag)
    }

  end

end
