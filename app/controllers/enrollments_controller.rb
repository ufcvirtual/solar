class EnrollmentsController < ApplicationController

  def index
    #if current_user
    #  @user = Enrollment.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @enrollment = Enrollment.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @enrollment }
    end
  end

  def new
    @enrollment = Enrollment.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @enrollment }
    end
  end

  def edit
    @enrollment = Enrollment.find(params[:id])
  end

  def create
    @enrollment = Enrollment.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @enrollment }
    end
  end

  def update
    @enrollment = Enrollment.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @enrollment }
    end
  end

  def destroy
    @enrollment = Enrollment.find(params[:id])
    @enrollment.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end
