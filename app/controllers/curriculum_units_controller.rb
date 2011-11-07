class CurriculumUnitsController < ApplicationController

  include CurriculumUnitsHelper
  include LessonsHelper
  include DiscussionPostsHelper
  include MessagesHelper

  before_filter :require_user, :only => [:new, :edit, :create, :update, :destroy, :show]
  before_filter :prepare_for_group_selection, :only => [:show, :participants, :informations]
  #before_filter :curriculum_data, :only => [:show, :informations, :participants]

  #  load_and_authorize_resource

  ##
  # Apresentacao de todas as informacoes relevantes para o usuario
  ##
  def show

    curriculum_data

    # recuperando informações da sessao
    active_tab = session[:opened_tabs][session[:active_tab]]

    group_id, offer_id, curriculum_unit_id = active_tab["groups_id"], active_tab["offers_id"], active_tab["id"]
    user_id = current_user.id

    message_tag = nil
    message_tag = get_label_name(curriculum_unit_id, offer_id, group_id) unless active_tab["type"] == Tab_Type_Home

    # retorna aulas, posts nos foruns e mensagens relacionados a UC mais atuais
    @lessons = return_lessons_to_open(offer_id, group_id)
    @discussion_posts = list_portlet_discussion_posts(offer_id, group_id)
    @messages = return_messages(current_user.id, 'portlet', message_tag)
    
    session[:lessons] = @lessons

    # destacando dias que possuem eventos
    schedules_events = Schedule.all_by_offer_id_and_group_id_and_user_id(offer_id, group_id || nil, user_id)
    schedules_events_dates = schedules_events.collect { |schedule_event|
      [schedule_event['start_date'], schedule_event['end_date']]
    }

    @scheduled_events = schedules_events_dates.flatten.uniq

  end

  def destroy
    @curriculum_unit.destroy

    respond_to do |format|
      format.html #{ redirect_to(users_url, :notice => 'Usuario excluido com sucesso!') }
      format.xml  { head :ok }
    end
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

    # retorna participantes da turma (que nao sejam responsaveis)
    responsible = false

    # Temporário: garantindo que haverá um grupo, pois futuramente será necessário escolher um grupo para visualizar os participantes
    #groups_id = Group.find_by_offer_id(offers_id).id unless !groups_id.nil?
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    @participants = class_participants groups_id, responsible

  end

  private

  def curriculum_data
    # localiza unidade curricular
    @curriculum_unit = CurriculumUnit.find(params[:id])

    # pegando dados da sessao e nao da url
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # localiza responsavel
    responsible = true

    @responsible = class_participants groups_id, responsible
  end

end
