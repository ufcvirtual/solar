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
      render json: { success: true, notice: t('academic_allocation_users.success.evaluated'), situation: t("scores.index.#{score}"), class_td: score }
    end
  end

  private
    def acu_params
      params.require(:academic_allocation_user).permit(:group_id, :user_id, :grade, :working_hours, :score_type)
    end

end