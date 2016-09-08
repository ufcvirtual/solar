class ToolsController < ApplicationController

  layout false

  def equalities
    at_id = active_tab[:url][:allocation_tag_id]
    raise CanCan::AccessDenied unless AllocationTag.find(at_id).is_student_or_responsible_or_observer?(current_user.id)

    if params[:ac_id].blank?
      @equalities = []
    else
      @tool = params[:tool_type].constantize.joins(:academic_allocations).where(academic_allocations: {id: params[:ac_id]}).first
      @equalities = params[:tool_type].constantize.joins(:academic_allocations).where(academic_allocations: {equivalent_academic_allocation_id: params[:ac_id], academic_tool_type: params[:tool_type]})
    end
  end

end