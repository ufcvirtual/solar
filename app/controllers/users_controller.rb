class UsersController < ApplicationController
	before_filter :require_no_user, :only => [:pwd_recovery, :pwd_recovery_send]
	before_filter :require_user, :only => [:index, :show, :mysolar, :edit, :update, :destroy, :update_photo]

  load_and_authorize_resource

  ######################
  # funcoes do RESTful #
  ######################

  # GET /users
  def index
    if current_user
      @user = User.find(current_user.id)
    end
    render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  # GET /users/new
  def new
    respond_to do |format|
      format.html {render :layout => 'login'}# new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  def create

    # resetando os valores
    @current_ability = nil
    @current_user = nil

#    @user = User.new(params[:user])

    #    garante que a senha não fique como "" o que é diferente do nulo e seria igual a senha
    #    params[:user]["password"] = nil if params[:user]["password"] == ""
    #    params[:user]["password_confirmation"] = nil if params[:user]["password_confirmation"] == ""
    #
    #    garante que o e-mail não fique como "" o que é diferente do nulo e seria igual ao e-mail
    #    params[:user]["email"] = nil if params[:user]["email"] == ""
    #    params[:user]["email_confirmation"] = nil if params[:user]["email_confirmation"] == ""

    if params["radio_special"] == "false"
      @user.special_needs = nil
    end

    @user.password = params[:user]["password"]
    #respond_to do |format|
      if (@user.save )

        #flash[:notice] = t(:new_user_msg_ok)
        #format.html { render :action => "mysolar"}
#        format.xml  { render :xml => @user, :status => :created, :location => @user }
        #msg = t(:new_user_msg_ok)

        # gera aba para Home e redireciona
        redirect_to :action => "add_tab", :controller => "application", :name => 'Home', :type => Tab_Type_Home
        
      else
        format.html { render :action => "new",:layout => "login" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    #end
  end

  # PUT /users/1
  def update

    #variavel para verificar se a mudança de senha passa nos testes
    sucesso = true
    error_msg = " "

    #Evita que os parametros nulo fiquem como " " no banco
    params[:user]["old_password"] = nil if params[:user]["old_password"] == ""
    params[:user]["new_password"] = nil if params[:user]["new_password"] == ""
    params[:user]["repeat_password"] = nil if params[:user]["repeat_password"] == ""

    #Validação da mudança de senha. Só entra nesse if maior se algum dos campos for preenchido
    # os campos são: Senha Antiga, Nova Senha e Confirmar Senha
    if ( !params[:user]["old_password"].nil? ||
          !params[:user]["new_password"].nil? ||
          !params[:user]["repeat_password"].nil?)

      antiga_senha  = params[:user]["old_password"]
      nova_senha    = params[:user]["new_password"]
      repetir_senha = params[:user]["repeat_password"]

      if (!antiga_senha.nil?)
        antiga_senha = CryptoProvider.encrypt(antiga_senha)
      end

      if (antiga_senha.nil?)
        sucesso = false
        error_msg = t('empty_old_password')
      else
        if (antiga_senha == @user[:crypted_password])
          if (nova_senha.nil? || repetir_senha.nil? || (nova_senha != repetir_senha))
            sucesso = false
            error_msg = t("bad_password_confirmation")
          end
        else
          sucesso = false
          error_msg = t('incorrect_old_password')
        end
      end
    end

    # Limpando os parametros da requisicao que nao fazem parte do MODEL
    params[:user].delete("old_password")
    params[:user].delete("new_password")
    params[:user].delete("repeat_password")

    #caso a mudança de senha esteja correta, altera a senha
    if (sucesso && !nova_senha.nil?)
      @user.crypted_password = CryptoProvider.encrypt(nova_senha)
    end

    respond_to do |format|
      if (sucesso && @user.update_attributes(params[:user]))
        flash[:success] = t('successful_update')
        format.html { redirect_to({:action => 'edit'})}
        format.xml { head :ok }
      else
        #joga as mensagens de validação do modelo nas mensagens de erro
        if @user.errors.any?
          @user.errors.full_messages.each do |msg|
            #remove a mensagem do brazillian rails
            if msg != 'CPF numero invalido'
              error_msg << msg+"<br/>"
            end
          end
        end
        flash[:error] = error_msg
        format.html {render({:action => 'edit'})}
        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  ##############################
  #     PORTLETS DO USUARIO    #
  ##############################
  def mysolar
    if current_user
      @user = User.find(current_user.id)
    end
  end

  ######################################
  # funcoes para verificacao de senhas #
  ######################################
  def pwd_recovery
  	if !@user
      @user = User.new
    end

    #if !@user_session
    #	@user_session = UserSession.new
    #end
    #render :action => pwd_recovery
    respond_to do |format|
      format.html { render :layout => 'login'}# new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  def pwd_recovery_send
    #se existe usuario com esse cpf e email, recupera
    user_find = User.find_by_cpf_and_email(params[:user][:cpf],params[:user][:email])

    if user_find
      #gera nova senha
      pwd = generate_password(8)
      user_find.password = pwd

      #altera senha do usuario e envia email
      if user_find.save!

        #remove sessao criada
        if current_user_session
          current_user_session.destroy
        end

        #envia email
        Notifier.deliver_recovery_new_pwd(user_find, pwd)

        flash[:notice] = t(:pwd_recovery_sucess_msg)
      else
        flash[:error] = t(:pwd_recovery_error_msg)
      end

    else
      flash[:error] = t(:pwd_recovery_unknown_user_msg)
    end

    respond_to do |format|
      format.html { redirect_to(users_pwd_recovery_url) }
      format.xml  { head :ok }
    end

  end

  def generate_password(size)
    accept_chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l)
  	(1..size).collect{|a| accept_chars[rand(accept_chars.size)] }.join
  end

  ##################################
  # modificacao da foto do usuario #
  ##################################
  def update_photo

    error_msg, redirect = " ", {:action => "mysolar"}

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:success] = t('successful_update_photo')
        format.html { redirect_to(redirect) }
        format.xml  { head :ok }
      else
        # joga as mensagens de validação do modelo nas mensagens de erro
        if @user.errors.any?
          msgs_error = @user.errors.full_messages.uniq # podem ter erros repetidos mas serao exibidos como unicos
          msgs_error.each do |msg|
            if msg.index("recognized by the 'identify'") # erro que nao teve tratamento
              # se aparecer outro erro nao exibe o erro de arquivo nao identificado
              if msgs_error.count == 1
                error_msg << t(:activerecord)[:attributes][:user][:photo_content_type] + " "
                error_msg << t(:activerecord)[:errors][:models][:user][:attributes][:photo_content_type][:invalid_type] + "<br />"
              end
            else # exibicao de erros conhecidos
              error_msg << msg + "<br />"
            end
          end
        end
        flash[:error] = error_msg
        format.html { render(redirect) }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

end
