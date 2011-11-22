class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list

    active_tab = session.include?('opened_tabs') ? session[:opened_tabs][session[:active_tab]] : []
    offer_id = active_tab.include?('offers_id') ? active_tab['offers_id'] : nil
    group_id = active_tab.include?('groups_id') ? active_tab['groups_id'] : nil

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
    active_tab = session.include?('opened_tabs') ? session[:opened_tabs][session[:active_tab]] : []
    offer_id = active_tab.include?('offers_id') ? active_tab['offers_id'] : nil
    group_id = active_tab.include?('groups_id') ? active_tab['groups_id'] : nil

    # apresentacao dos links de todas as schedules
    @link, offer_id, group_id = false, nil, nil unless params[:list_all_schedule].nil?
    @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(offer_id, group_id, user_id, period, date)

    render :layout => false
  end

end
