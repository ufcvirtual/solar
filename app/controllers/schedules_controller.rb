class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list

    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id
    curriculum_unit_id = params[:id]

    @curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
    @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(offer_id, group_id, user_id)

  end

  ##
  # Exibição de links da agenda
  ##
  def show
    @link, user_id, date = true, current_user.id, Date.parse(params[:date])

    period = true
    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # apresentacao dos links de todas as schedules
    @link, offer_id, group_id = false, nil, nil unless params[:list_all_schedule].nil?
    @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(offer_id, group_id, user_id, period, date)

    render :layout => false
  end

end
