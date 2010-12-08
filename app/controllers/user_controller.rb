class UserController < ApplicationController
  before_filter :require_user, :only => [:index, :show, :mysolar, :edit, :update, :destroy]
	# requerem q usuario esteja logado

  def index
	if current_user
		@user = User.find(current_user.id)
	end
	render :action => :mysolar
  end

  def show
	if params[:id]
		@user = User.find(params[:id])
	end
  end

  def mysolar
	if current_user
		@user = User.find(current_user.id)
	end
  end

  def new
    @user = User.new
  end
  def create
    @user = User.new(params[:user])
    # flash trafega msgs - armazena msg ate q a pag seja redirecionada
    if @user.save
      #flash[:aviso] = 'Usuário criado com sucesso!'   # msg do tipo aviso
    else
      #flash[:erro] = 'Erro criando usuário!'          # msg do tipo erro
    end
    redirect_to (@user)
  end

  def edit
    @user = User.find(params[:id])
  end
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      #flash[:aviso] = 'Usuário atualizado com sucesso!'
      redirect_to (@user)
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    #flash[:info] = 'Usuário excluído com sucesso!'
    redirect_to (users_path)
  end

end
