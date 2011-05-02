class CoursesController < ApplicationController

  load_and_authorize_resource

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
    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def new
    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def update
    respond_to do |format|
      format.html
      format.xml  { render :xml => @course }
    end
  end

  def destroy
    @course.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

end