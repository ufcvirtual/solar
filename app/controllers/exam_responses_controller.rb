class ExamResponsesController < ApplicationController
    
  include SysLog::Actions

  layout false

  def update
    #authorize! :update, ExamResponse, { on: @allocation_tags_ids = params[:allocation_tags_ids] }
    @exam_response = ExamResponse.find(params[:id])
    @exam_user_attempt =  ExamUserAttempt.find(@exam_response.exam_user_attempt_id)
    total_time = @exam_user_attempt.get_total_time

    user_validate = @exam_user_attempt.user.id == current_user.id ? true : false
    attempt_validate = @exam_user_attempt.id == params[:exam_response][:exam_user_attempt_id].to_i ? true : false
    duration_validate = @exam_user_attempt.exam.duration > total_time ? true : false
    status_validate = @exam_user_attempt.exam.status

    if (user_validate && attempt_validate && duration_validate && status_validate)
      if @exam_response.update_attributes(exam_response_params) 
        render_exam_response_success_json('updated')
      end
    else
      if @exam_user_attempt.complete
        render_exam_response_success_json('updated')
      elsif (!duration_validate || !status_validate)
        ExamUserAttempt.finish_attempt(@exam_user_attempt.id)
        respond_to do |format|
          format.js { render :js => "validation_error('#{I18n.t('exam_responses.error.duration')}');" }
        end
      else
        respond_to do |format|
          format.js { render :js => "validation_error('#{I18n.t('exam_responses.error.validate')}');" }
        end
      end
    end
   end

  private

    def exam_response_params
      params.require(:exam_response).permit(:id, :exam_user_attempt_id, :value, :duration, :exam_user_attempt_id, :question_id, question_item_ids:[])
    end

    def render_exam_response_success_json(method)
      render json: { success: true, notice: t(method, scope: 'exam_responses.success') }
    end
end