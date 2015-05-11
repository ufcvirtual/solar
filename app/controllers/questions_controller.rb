class QuestionsController < ApplicationController

    include SysLog::Actions

    layout false, except: :index

  def new
    # authorize! :create, Question, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @question = Question.new
    @question.question_images.build
    @question.question_labels.build
    @question.question_items.build
  end

  private

  def question_params
    params.require(:question).permit(:name, :enunciation, :type_question)
  end

end