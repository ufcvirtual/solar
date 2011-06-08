class MessagesController < ApplicationController

  include MessagesHelper
  
  before_filter :require_user
  before_filter :message_data, :only => [:index]

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

private

  def message_data
    # verifica aba aberta, se Home ou se aba de unidade curricular
    # se Home, traz todas; senao, traz com filtro da unidade curricular
    if session[:opened_tabs][session[:active_tab]]["type"] != Tab_Type_Home
      @message_tag = session[:active_tab]
    else
      @message_tag = nil
    end
  end

end
