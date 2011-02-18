class ClassesController < ApplicationController

  def index
    #if current_user
    #  @user = Class.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @class = Class.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @class }
    end
  end

  def new
    @class = Class.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @class }
    end
  end

  def edit
    @class = Class.find(params[:id])
  end

  def create
    @class = Class.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @class }
    end
  end

  def update
    @class = Class.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @class }
    end
  end

  def destroy
    @class = Class.find(params[:id])
    @class.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end
