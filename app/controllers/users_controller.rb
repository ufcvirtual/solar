class UsersController < ApplicationController
	before_filter :require_no_user, :only => [:pwd_recovery, :pwd_recovery_send]
	before_filter :require_user, :only => [:index, :show, :mysolar, :edit, :update, :destroy]

  # GET /users
  # GET /users.xml
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

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html {render :layout => 'login'}# new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

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
    respond_to do |format|
      if (@user.save )
        msg = t(:new_user_msg_ok)
        format.html { render :action => "mysolar", :notice=>msg}
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new",:layout =>"login" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update

    #variavel para verificar se a mudança de senha passa nos testes
    sucesso = true
    error_msg = " "

    #Evita que os parametros nulo fiquem como " " no banco
    params[:user]["old_password"] = nil if params[:user]["old_password"] == ""
    params[:user]["new_password"] = nil if params[:user]["new_password"] == ""
    params[:user]["repeat_password"] = nil if params[:user]["repeat_password"] == ""
    #recupera o usuario que esta sendo editado
    @user = User.find(params[:id])

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
        error_msg = "Senha antiga vazia"
      else
        if (antiga_senha == @user[:crypted_password])
          if (nova_senha.nil? || repetir_senha.nil? || (nova_senha != repetir_senha))
            sucesso = false
            error_msg = "A nova senha e a confirmacao nao conferem !"
          end
        else
          sucesso = false
          error_msg = "Senha antiga incorreta"
        end
      end
    end
    #Limpando os parametros da requisicao que nao fazem parte do MODEL
    params[:user].delete("old_password")
    params[:user].delete("new_password")
    params[:user].delete("repeat_password")

    #caso a mudança de senha esteja correta, altera a senha
    if (sucesso && !nova_senha.nil?)
      @user.crypted_password =  CryptoProvider.encrypt(nova_senha)
    end
    respond_to do |format|
      if (sucesso && @user.update_attributes(params[:user]))
        flash[:success] = 'Usuario alterado com sucesso!'
        format.html { redirect_to({:controler=>"users",:action=>"mydata"})}
        format.xml  { head :ok }
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
        format.html {render ({:controler=>"users",:action=>"mydata"})}
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def mysolar
    if current_user
      @user = User.find(current_user.id)
    end
  end

  def mydata
    if current_user
      @user = User.find(current_user.id)
    end
  end
  
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
      pwd = generate_password (8)
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
  
  def generate_password (size)
    accept_chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l)
  	(1..size).collect{|a| accept_chars[rand(accept_chars.size)] }.join
  end
  
end
