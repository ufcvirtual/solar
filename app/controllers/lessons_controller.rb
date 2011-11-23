class LessonsController < ApplicationController

  #  include LessonsHelper

  #  before_filter :require_user, :only => [:list, :show]
  before_filter :prepare_for_group_selection, :only => [:list]

  before_filter :curriculum_data, :only => [:list, :show, :show_header, :show_content]

  load_and_authorize_resource :except => [:list]

  def show
    render :layout => 'lesson_frame'
  end

  def show_header
    render :layout => 'lesson'
  end

  def show_content
    render :layout => 'lesson'
  end

  def list
    authorize! :list, Lesson

    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]

    # retorna aulas
    @lessons = Lesson.to_open(active_tab['allocation_tag_id'])

    # guarda lista de aulas para navegacao
    user_session[:lessons] = @lessons

  end

  private

  def curriculum_data
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    @curriculum_unit = CurriculumUnit.find(active_tab['id']) if active_tab.include?('id')
  end

end
