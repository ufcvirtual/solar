class ExamResponsesController < ApplicationController

  include SysLog::Actions

  layout false

  def update
    exam_response = ExamResponse.find(params[:id])
    exam_user_attempt = exam_response.exam_user_attempt
    exam = Exam.find(exam_user_attempt.exam.id)
    if exam.controlled && exam.network_ips_permited_to_do_the_exams(get_remote_ip).blank?
      render text: t('exams.restrict_test')
    else
      total_time = exam_user_attempt.get_total_time(params[:id], exam_response_params[:duration].to_i)

      user_validate     = (exam_user_attempt.user.id == current_user.id)
      attempt_validate  = (exam_user_attempt.id == params[:exam_response][:exam_user_attempt_id].to_i)
      duration_validate = (exam_user_attempt.exam.duration*60 > total_time)
      date_validate     = exam_user_attempt.exam.on_going?

      if (user_validate && attempt_validate && duration_validate && date_validate)
        if exam_response.update_attributes(exam_response_params)
          render_exam_response_success_json('updated')
        end
      else
        if exam_user_attempt.complete
          render_exam_response_success_json('updated')
        elsif (!duration_validate || !date_validate)
          redirect_to controller: 'exams', action: 'complete', id: exam_user_attempt.exam.id, error: 'duration'
        else
          redirect_to controller: 'exams', action: 'complete', id: exam_user_attempt.exam.id, error: 'validate'
        end
      end
    end
  end

  private

    def exam_response_params
      params.require(:exam_response).permit(:id, :exam_user_attempt_id, :duration, exam_responses_question_items_attributes:[:id, :value])
    end

    def render_exam_response_success_json(method)
      render json: { success: true, notice: t(method, scope: 'exam_responses.success') }
    end
end
