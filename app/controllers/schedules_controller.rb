class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list

    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]]['allocation_tag_id']
    allocation_tag = AllocationTag.find(allocation_tag_id)

    curriculum_unit_id = params[:id]

    @curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
    @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(allocation_tag.offer_id, allocation_tag.group_id, current_user.id)

  end

  ##
  # Exibição de links da agenda
  ##
  def show
    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]]['allocation_tag_id']
    allocation_tag = AllocationTag.find(allocation_tag_id)
    period = true

    # apresentacao dos links de todas as schedules
    @link = params[:list_all_schedule].nil? ? false : true
    @schedule = Schedule.all_by_offer_id_and_group_id_and_user_id(allocation_tag.offer_id, allocation_tag.group_id, current_user.id, period, Date.parse(params[:date]))

    render :layout => false
  end

end
