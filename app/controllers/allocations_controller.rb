class AllocationsController < ApplicationController

  def index
    #if current_user
    #  @user = Allocation.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @allocation = Allocation.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  def new
    @allocation = Allocation.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  def edit
    @allocation = Allocation.find(params[:id])
  end

  def create
    @allocation = Allocation.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  def update
    @allocation = Allocation.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @allocation }
    end
  end

  def destroy
    @allocation = Allocation.find(params[:id])
    @allocation.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end
