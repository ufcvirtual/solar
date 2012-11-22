class SchedulesController < ApplicationController
  before_filter :prepare_for_group_selection, :only => :list

  def list
    @schedule = Schedule.events(current_user.allocation_tags.map(&:related).flatten.uniq.sort)
  end

  def show
    allocation_tags = active_tab[:url]['allocation_tag_id'].nil? ? nil : AllocationTag.find(active_tab[:url]['allocation_tag_id']).related
    @link           = not(params[:list_all_schedule].nil?) # apresentacao dos links de todas as schedules
    @schedule       = Schedule.events(allocation_tags, true, Date.parse(params[:date]))

    render :layout => false
  end

end
