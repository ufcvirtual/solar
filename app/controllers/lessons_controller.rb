class LessonsController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]
  before_filter :curriculum_data

  load_and_authorize_resource :except => [:list]

  def show
    render :layout => 'lesson_frame'
  end

  def show_header
    @lessons = lessons_to_open
    render :layout => 'lesson'
  end

  def show_content
    render :layout => 'lesson'
  end

  def list
    authorize! :list, Lesson

    @lessons = lessons_to_open
  end

  private

  def curriculum_data
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    @curriculum_unit = CurriculumUnit.find(active_tab['id']) if active_tab.include?('id')
  end

  def lessons_to_open
    Lesson.to_open(user_session[:tabs][:opened][user_session[:tabs][:active]]['allocation_tag_id'])
  end

end
