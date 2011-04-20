class CurriculumUnitsController < ApplicationController

  include ParticipantsHelper

#  load_and_authorize_resource

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :access]

  before_filter :curriculum_data, :only => [:access, :informations]

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
  end

  def informations
  end

  private

  def curriculum_data

    params[:offers_id] ||= nil
    params[:groups_id] ||= nil

    # localiza unidade curricular
    @curriculum_unit = CurriculumUnit.find(params[:id])
    # localiza responsavel
    responsible = true
    @responsible = class_participants(params[:id], responsible, params[:offers_id], params[:groups_id])
  end

end
