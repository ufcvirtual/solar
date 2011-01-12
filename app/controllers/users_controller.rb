class UsersController < ApplicationController
	before_filter :require_user, :only => [:index, :show, :mysolar, :edit, :update, :destroy]
	# requerem q usuario esteja logado

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
      format.html # new.html.erb
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

    #garante que a senha não fique como "" o que é diferente do nulo e seria igual a senha
    params[:user]["password"] = nil if params[:user]["password"] == ""
    params[:user]["password_confirmation"] = nil if params[:user]["password_confirmation"] == ""

    if params["radio_special"] == "false"
      @user.special_needs = nil
    end

    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'Usuario criado com sucesso!') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
	#flash[:erro] = 'Erro criando usu�rio!'          # msg do tipo erro
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'Usuario atualizado com sucesso!') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
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
end
