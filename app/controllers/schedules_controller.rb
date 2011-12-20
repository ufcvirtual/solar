class SchedulesController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocation_tags = allocation_tag_id.nil? ? nil : AllocationTag.find_related_ids(allocation_tag_id).join(', ')

    @curriculum_unit = CurriculumUnit.find(active_tab[:url]['id']) unless active_tab[:url]['id'].nil?
    @schedule = Schedule.all_by_allocation_tags(allocation_tags)
  end

  ##
  # Exibição de links da agenda
  ##
  def show
    allocation_tag_id = active_tab[:url]['allocation_tag_id']
    allocation_tags = allocation_tag_id.nil? ? nil : AllocationTag.find_related_ids(allocation_tag_id).join(', ')
    period = true

    # apresentacao dos links de todas as schedules
    @link = params[:list_all_schedule].nil? ? false : true
    @schedule = Schedule.all_by_allocation_tags(allocation_tags, period, Date.parse(params[:date]))

    render :layout => false
  end

end
