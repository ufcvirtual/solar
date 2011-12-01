class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocations = AllocationTag.find_related_ids(allocation_tag_id)

    @curriculum_unit = CurriculumUnit.find(active_tab[:url]['id'])
    @schedule = Schedule.all_by_allocations(allocations.join(', '))
  end

  ##
  # Exibição de links da agenda
  ##
  def show
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocations = AllocationTag.find_related_ids(allocation_tag_id)
    period = true

    # apresentacao dos links de todas as schedules
    @link = params[:list_all_schedule].nil? ? false : true
    @schedule = Schedule.all_by_allocations(allocations.join(', '), period, Date.parse(params[:date]))

    render :layout => false
  end

end
