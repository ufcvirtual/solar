class ExamQuestionsController < ApplicationController

    include SysLog::Actions

    layout false, except: :index

  def new
    # authorize! :create, ExamQuestion, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @exam_question = ExamQuestion.new
    # @exam_question.question = Question.new
    @exam_question.build_question
  end

    private

    def exam_question_params
      # raise "#{params}"
      params.require(:exam_question).permit(:score,
                                   question_attributes: [:id, :name, :enunciation, :type_question])
    end
end