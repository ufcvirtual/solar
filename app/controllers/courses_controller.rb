class CoursesController < ApplicationController

  def index
    #if current_user
    #  @user = Course.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @course = Course.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def new
    @course = Course.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def edit
    @course = Course.find(params[:id])
  end

  def create
    @course = Course.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def update
    @course = Course.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end