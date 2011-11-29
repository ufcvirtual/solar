class UsersController < ApplicationController

  include ApplicationHelper

  load_and_authorize_resource

  # GET /users
  def index
    render :action => :mysolar
  end

  # GET /users/new
#  def new
#    respond_to do |format|
#      format.html {render :layout => 'login'}
#      format.xml {render :xml => @user}
#    end
#  end

  # GET /users/1/edit
  def edit
    # utilizando devise
    set_active_tab_to_home
    render :action => :mysolar
#    redirect_to :action => "edit", :controller => "devise/registrations"
  end

  # POST /users
#  def create
#
#    @user.special_needs = nil if params["radio_special"] == "false"
#    @user.password = params[:user]["password"]
#
#    if (@user.save)
#      # gera aba para Home e redireciona
#      redirect_to :action => "add_tab", :controller => "application", :name => 'Home', :type => Tab_Type_Home
#    else
#      respond_to do |format|
#        format.html { render :action => "new", :layout => "login" }
#        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # PUT /users/1
#  def update
#    # utilizando devise
#  end
#
#  # DELETE /users/1
#  def destroy
#    @user.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
#      format.xml  { head :ok }
#    end
#  end

  ##############################
  #     PORTLETS DO USUARIO    #
  ##############################

  def mysolar

    set_active_tab_to_home
    @user = current_user

    ######
    # Portlet do calendario
    # destacando dias que possuem eventos
    ######
    schedules_events = Schedule.all_by_offer_id_and_group_id_and_user_id(nil, nil, current_user.id)
    schedules_events_dates = schedules_events.collect { |schedule_event|
      [schedule_event['start_date'], schedule_event['end_date']]
    }

    @scheduled_events = schedules_events_dates.flatten.uniq
  end

  ######################################
  # funcoes para verificacao de senhas #
  ######################################

#  def pwd_recovery
#    #  	if !@user
#    #      @user = User.new
#    #    end
#
#    respond_to do |format|
#      format.html { render :layout => 'login'}
#      format.xml  { render :xml => @user }
#    end
#  end
#
#  def pwd_recovery_send
#    #se existe usuario com esse cpf e email, recupera
#    user_find = User.find_by_cpf_and_email(params[:user][:cpf], params[:user][:email])
#
#    if user_find
#      #gera nova senha
#      pwd = generate_password(8)
#      user_find.password = pwd
#
#      #altera senha do usuario e envia email
#      if user_find.save!
#
#        #remove sessao criada
#        if current_user_session
#          current_user_session.destroy
#        end
#
#        #envia email
#        Notifier.deliver_recovery_new_pwd(user_find, pwd)
#
#        flash[:notice] = t(:pwd_recovery_sucess_msg)
#      else
#        flash[:error] = t(:pwd_recovery_error_msg)
#      end
#
#    else
#      flash[:error] = t(:pwd_recovery_unknown_user_msg)
#    end
#
#    respond_to do |format|
#      format.html { redirect_to(users_pwd_recovery_url) }
#      format.xml  { head :ok }
#    end
#
#  end

#  def generate_password(size)
#    accept_chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l)
#  	(1..size).collect{|a| accept_chars[rand(accept_chars.size)] }.join
#  end

  ##################################
  # modificacao da foto do usuario #
  ##################################

  def update_photo

    redirect = session[:breadcrumb].last[:url]

    respond_to do |format|
      begin

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:user) && params[:user].include?(:photo)

        @user.update_attributes!(params[:user])

        flash[:success] = t(:successful_update_photo)
        format.html { redirect_to(redirect) }

      rescue Exception => error

        error_msg = ''
        if error.message.index("not recognized by the 'identify'") # erro que nao teve tratamento
          # se aparecer outro erro nao exibe o erro de arquivo nao identificado
          error_msg << t(:activerecord)[:attributes][:user][:photo_content_type] + " "
          error_msg << t(:activerecord)[:errors][:models][:user][:attributes][:photo_content_type][:invalid_type] + "<br />"
        else # exibicao de erros conhecidos
          error_msg << error.message
        end

        flash[:error] = error_msg
        format.html { redirect_to(redirect) }
      end
    end

  end

end
