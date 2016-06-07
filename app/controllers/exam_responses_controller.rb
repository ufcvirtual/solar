class ExamResponsesController < ApplicationController
    
  include SysLog::Actions

  layout false

  def new
    # authorize! :create, ExamResponse, { on: @allocation_tags_ids = params[:allocation_tags_ids] }
    @exam_response = ExamResponse.new
  end

  def create
    @exam_response = ExamResponse.new exam_response_params
    @exam_response.save
    # if @exam_response.save
    #   redirect_to action: "...", id: @...
    #   else
    #   render action: "..."
    # end
    respond_to do |format|
      format.js { render json: {success: true}  }
    end
  end

  def update
    #authorize! :update, ExamResponse, { on: @allocation_tags_ids = params[:allocation_tags_ids] }
    @exam_response = ExamResponse.find(params[:id])

    complete = ExamUserAttempt.find(@exam_response.exam_user_attempt_id).complete

    if complete == false
      if @exam_response.update_attributes(exam_response_params) 
        render_exam_response_success_json('updated')
      else
      # render :...
      end
    else
      render_exam_response_success_json('updated')
    end  
    # end

    # respond_to do |format|
    #   format.js { render json: {success: true}  }
    # end
  end

  private

    def exam_response_params
      params.require(:exam_response).permit(:id, :exam_user_attempt_id, :value, :duration, :exam_user_attempt_id, :question_id, question_item_ids:[])
    end

    def render_exam_response_success_json(method)
      render json: { success: true, notice: t(method, scope: 'exam_responses.success') }
    end
end