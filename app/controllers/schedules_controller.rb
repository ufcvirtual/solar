class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list

    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    curriculum_unit_id = params[:id]

    @curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
    @schedule = Schedule.all_by_curriculum_unit_id_and_offer_id_group_id_and_user_id(curriculum_unit_id, offer_id, group_id, user_id)

  end

  def show
    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    curriculum_unit_id = params[:id]
    date = params[:date]
    period = true

    # tem q considerar a data q tu passou
    @schedule = Schedule.all_by_curriculum_unit_id_and_offer_id_group_id_and_user_id(curriculum_unit_id, offer_id, group_id, user_id, period, date)

    render :layout => false

  end

end
