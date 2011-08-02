class CurriculumUnitsController < ApplicationController

  include CurriculumUnitsHelper
  include LessonsHelper
  include DiscussionPostsHelper

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :access]

  before_filter :curriculum_data, :only => [:access, :informations, :participants]

  load_and_authorize_resource

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
    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def new
    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def update
    respond_to do |format|
      format.html
      format.xml  { render :xml => @curriculum_unit }
    end
  end

  def destroy
    @curriculum_unit.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
  end

  def access
    # pegando dados da sessao e nao da url
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    
    # retorna aulas
    @lessons = return_lessons_to_open(offers_id, groups_id)
    @discussion_posts = list_portlet_discussion_posts(offers_id, groups_id)
    session[:lessons] = @lessons
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
