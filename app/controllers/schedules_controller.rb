class SchedulesController < ApplicationController
  before_filter :prepare_for_group_selection, only: :list

  def index
     # se não estiver em uma uc específica, recupera as allocations tags ativadas do usuário
    @allocation_tags = (active_tab[:url][:allocation_tag_id].nil?) ? current_user.activated_allocation_tag_ids : AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
    @link            = not(params[:list_all_schedule].nil?) # apresentacao dos links de todas as schedules
    @schedule        = Schedule.events(@allocation_tags, true, Date.parse(params[:date])) 
    render layout: false
  end

  def list
    allocation_tags = active_tab[:url][:allocation_tag_id] || params[:allocation_tags_ids]
    @schedule       = Schedule.events(allocation_tags)
  end

end
