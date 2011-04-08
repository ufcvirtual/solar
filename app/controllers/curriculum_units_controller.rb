class CurriculumUnitsController < ApplicationController

  def index
    #if current_user
    #  @user = CurriculumUnit.find(current_user.id)
    #end
    #render :action => :mysolar

    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @users }
    #end
  end

  def show
    @curriculum_unit = CurriculumUnit.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def new
    @curriculum_unit = CurriculumUnit.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def edit
    @curriculum_unit = CurriculumUnit.find(params[:id])
  end

  def create
    @curriculum_unit = CurriculumUnit.new(params[:user])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def update
    @curriculum_unit = CurriculumUnit.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def destroy
    @curriculum_unit = CurriculumUnit.find(params[:id])
    @curriculum_unit.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def access
    @curriculum_unit = CurriculumUnit.find (params[:id])

    if current_user
      @user = User.find(current_user.id)
    end
    
  end

end
