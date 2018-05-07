class AcademicAllocationUsersController < ApplicationController

  include SysLog::Actions

  def evaluate
    authorize! :evaluate, params[:tool].constantize, on: [at_id = active_tab[:url][:allocation_tag_id]]

    result = AcademicAllocationUser.create_or_update(params[:tool], params[:id], at_id, {user_id: acu_params[:user_id], group_assignment_id: acu_params[:group_id]}, {grade: acu_params[:grade], working_hours: acu_params[:working_hours]})
    if params[:tool] == Exam
      Exam.find(params[:id]).recalculate_grades(acu_params[:user_id]) rescue nil
    end
    @academic_allocation_user = AcademicAllocationUser.where(id: result[:id]).first
    errors = result[:errors]
    score = Score.evaluative_frequency_situation(at_id, acu_params[:user_id], acu_params[:group_id], params[:id], params[:tool].downcase, acu_params[:score_type]).first.situation

    if errors.any?
      render json: { success: false, alert: errors.join("<br/>") }, status: :unprocessable_entity
    else
      if !@academic_allocation_user.academic_allocation.try(:equivalent_academic_allocation_id).blank? && AcademicAllocationUser.where(academic_allocation_id: @academic_allocation_user.academic_allocation.equivalent_academic_allocation_id, user_id: @academic_allocation_user.user_id).any?
        render json: { success: true, warning: t('academic_allocation_users.warning.equivalency_evaluated'), situation: t("scores.index.#{score}"), class_td: score, situation_complete: t(score.to_sym) }
      else
        render json: { success: true, notice: t('academic_allocation_users.success.evaluated'), situation: t("scores.index.#{score}"), class_td: score, situation_complete: t(score.to_sym) }
      end
    end

  rescue => error
    render json: { success: false, alert: errors.join("<br/>") }, status: :unprocessable_entity
  end

  def summary
    at = active_tab[:url][:allocation_tag_id]
    ac_id = (params[:ac_id].blank? ? AcademicAllocation.where(academic_tool_type: params[:tool], academic_tool_id: (params[:tool_id]), allocation_tag_id: at).first.try(:id) : params[:ac_id])

    @acu = AcademicAllocationUser.find_or_create_one(ac_id, at, current_user.id, params[:group_id], false, nil)
    @files = ScheduleEventFile.where(academic_allocation_user_id: @acu.id)
    @tool = params[:tool].constantize.find(params[:tool_id])

    @user = current_user

    render partial: 'comments/summary'
  end

  def files_sent
    at = active_tab[:url][:allocation_tag_id]
    ac_id = (params[:ac_id].blank? ? AcademicAllocation.where(academic_tool_type: params[:tool], academic_tool_id: (params[:tool_id]), allocation_tag_id: at).first.try(:id) : params[:ac_id])

    user_id = (params[:user_id].blank? ? current_user.id : params[:user_id])
    acu = AcademicAllocationUser.find_or_create_one(ac_id, at, user_id, params[:group_id], false, nil)

    @allocation_tag_id = at
    @files = ScheduleEventFile.where(academic_allocation_user_id: acu.id)
    @tool = params[:tool].constantize.find(params[:tool_id])

    render partial: 'schedule_event_files/summary'
  end

  private
    def acu_params
      params.require(:academic_allocation_user).permit(:group_id, :user_id, :grade, :working_hours, :score_type)
    end

end
