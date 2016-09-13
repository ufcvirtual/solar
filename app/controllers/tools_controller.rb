class ToolsController < ApplicationController

  layout false

  def equalities
    at_id = active_tab[:url][:allocation_tag_id]
    if at_id.blank?
      authorize! :preview, Webconference, { on: @at_id, accepts_general_profile: true }
    else
      raise CanCan::AccessDenied unless AllocationTag.find(at_id).is_student_or_responsible_or_observer?(current_user.id)
    end

    if params[:ac_id].blank?
      if params[:id].blank?
        @equalities = []
      else
        @tool = params[:tool_type].constantize.find(params[:id])
        acs   = @tool.academic_allocations.pluck(:id)

        @equalities = params[:tool_type].constantize.joins(:academic_allocations).where(academic_allocations: {equivalent_academic_allocation_id: acs, academic_tool_type: params[:tool_type]})
      end
    else
      @tool = params[:tool_type].constantize.joins(:academic_allocations).where(academic_allocations: {id: params[:ac_id]}).first
      @equalities = params[:tool_type].constantize.joins(:academic_allocations).where(academic_allocations: {equivalent_academic_allocation_id: params[:ac_id], academic_tool_type: params[:tool_type]})
    end
  end

end