class CurriculumUnitsController < ApplicationController

  include CurriculumUnitsHelper
  include LessonsHelper
  include DiscussionPostsHelper
  include MessagesHelper

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :access]
  before_filter :prepare_for_group_selection, :only => [:access, :participants, :informations]
  #before_filter :curriculum_data, :only => [:access, :informations, :participants]

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
    curriculum_data
    # pegando dados da sessao e nao da url
    message_tag = nil
    if session[:opened_tabs][session[:active_tab]]["type"] != Tab_Type_Home
      groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
      offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
      curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]

      message_tag = get_label_name(curriculum_unit_id, offers_id, groups_id)
    end

    # retorna aulas, posts nos foruns e mensagens relacionados a UC mais atuais
    @lessons = return_lessons_to_open(offers_id, groups_id)
    @discussion_posts = list_portlet_discussion_posts(offers_id, groups_id)
    @messages = return_messages(current_user.id, 'portlet', message_tag)
    session[:lessons] = @lessons

    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    @schedule_portlet = CurriculumUnit.select_for_schedule_in_portlet(groups_id, user_id, curriculum_unit_id)

  end

  def informations
    curriculum_data
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    @offer = offers_id.nil? ? nil : Offer.find(offers_id)
  end

  def participants
    curriculum_data
    #retorna perfil em que se pede matricula (~aluno)
    @student_profile = student_profile

    # pegando dados da sessao e nao da url
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    # retorna participantes da turma (que nao sejam responsaveis)
    responsible = false

    # Temporário: garantindo que haverá um grupo, pois futuramente será necessário escolher um grupo para visualizar os participantes
    #groups_id = Group.find_by_offer_id(offers_id).id unless !groups_id.nil?
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    @participants = class_participants groups_id, responsible

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
    # Temporário: garantindo que haverá um grupo, pois futuramente será necessário escolher um grupo para visualizar os participantes
    # groups_id = Group.find_by_offer_id(offers_id).id unless !groups_id.nil?

    @responsible = class_participants groups_id, responsible

    # pegando valores pela url:
    #@responsible = class_participants params[:id], responsible, params[:offers_id], params[:groups_id]
  end

end
