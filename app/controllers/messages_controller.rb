class MessagesController < ApplicationController

  include MessagesHelper
  
  before_filter :require_user
  before_filter :message_data #, :only => [:index, :new]

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
  end

  def show
    if !params[:id].nil?
      message_id = params[:id]

      if has_permission(message_id)
        @message = Message.find(message_id)
        @sender  = get_sender message_id
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

  def record
    id = params[:id]
  end

  # retorna usuario que enviou a msg
  def get_sender(message_id)
    return UserMessage.find :all, :conditions => ["message_id = ? and cast( status & '00000001' as boolean)", message_id]
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
