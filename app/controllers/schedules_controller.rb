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

  def show

    # verifica se exibe o link para visualizar a agenda completa
    @link = true
    user_id = current_user.id
    date = params[:date]
    period = true

    # requisicao vinda do mysolar
    unless params[:list_all_schedule].nil?
      @link = false
      @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(nil, nil, user_id, period, date)
    else
      offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
      group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
      # tem q considerar a data q tu passou
      @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(offer_id, group_id, user_id, period, date)
    end

    render :layout => false

  end

end
