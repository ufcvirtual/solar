class CurriculumUnitsController < ApplicationController

  include CurriculumUnitsHelper

#  load_and_authorize_resource

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :access]

  before_filter :curriculum_data, :only => [:access, :informations, :participants]

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
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    @offer = offers_id.nil? ? nil : Offer.find(offers_id)
  end

  def participants
    #retorna perfil em que se pede matricula (~aluno)
    @student_profile = student_profile

    # pegando dados da sessao e nao da url
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
   
    # retorna participantes da turma (que nao sejam responsaveis)
    responsible = false
    @participants = class_participants params[:id], responsible, offers_id, groups_id

    # pegando valores pela url:
    #@participants = class_participants params[:id], responsible, params[:offers_id], params[:groups_id]
  end

  private

  def curriculum_data
    # localiza unidade curricular
    @curriculum_unit = CurriculumUnit.find(params[:id])

    # pegando dados da sessao e nao da url
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    # localiza responsavel
    responsible = true
    @responsible = class_participants params[:id], responsible, offers_id, groups_id

    # pegando valores pela url:
    #@responsible = class_participants params[:id], responsible, params[:offers_id], params[:groups_id]
  end

end
