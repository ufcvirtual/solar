module ScheduleEventFilesHelper

  def get_ac
    @ac = AcademicAllocation.where(academic_tool_type: 'ScheduleEvent', academic_tool_id: (params[:tool_id] || params[:id]), allocation_tag_id: active_tab[:url][:allocation_tag_id]).first
  end

end
