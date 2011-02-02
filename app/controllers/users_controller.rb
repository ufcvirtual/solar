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
        #format.html { redirect_to(@user, :notice => 'Usuario criado com sucesso!') }
        format.html { render :action => "mysolar"}
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        #flash[:erro] = 'Erro criando usu�rio!'          # msg do tipo erro
        format.html { render :action => "new",:layout =>"login" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|

      if (@user.update_attributes(params[:user]))
      #if (@user.update_attributes!(:bio => params[:user][:bio]))
        #Ver se precisa mesmo deste redirect.
        #format.html { redirect_to(@user, :notice => 'Usuario atualizado com sucesso!') }
        format.html { render :action => "mydata"}
        format.xml  { head :ok }
      else
        #format.html { render :action => "edit" }
        format.html { render :action => "mydata" }
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
			
		#altera senha do usuario e envia email
		if user_find.update_attributes(:password => pwd)

			#envia email
		
			#remove sessao criada
			current_user_session.destroy
		
			msg = 'Senha enviada com sucesso!'
			
		else
			msg = 'Nao foi possivel enviar nova senha. Por favor, tente novamente.'
		end
				
	else
		msg = 'Usuario nao encontrado!'
	end	
	
	respond_to do |format|
	  format.html { redirect_to(users_pwd_recovery_url, :notice => msg) }
	  format.xml  { head :ok }
	end
	
  end
  
  def generate_password (size)
	accept_chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l)
  	(1..size).collect{|a| accept_chars[rand(accept_chars.size)] }.join
  end
  
end
