class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]
  
  def list

    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    curriculum_unit_id = params[:id]

    @curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
    @schedule = Schedule.all_by_group_id_and_user_id_and_curriculum_unit_id(group_id, user_id, curriculum_unit_id)

  end

  def show
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    curriculum_unit_id = params[:id]
    date = params[:date]

    # tem q considerar a data q tu passou
    @ajax = CurriculumUnit.select_for_schedule_in_portlet(group_id, user_id, curriculum_unit_id, date)

    render :layout => false

  end

end
