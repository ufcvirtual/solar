class GroupsController < ApplicationController

  def index
    #if current_user
    #  @user = Group.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def new
    @group = Group.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def create
    @group = Group.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @group }
    end
  end

  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end
