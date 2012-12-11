class LessonFilesController < ApplicationController

  def index
    lesson = Lesson.find(params[:lesson_id])
    file = File.join(Lesson::FILES_PATH, params[:lesson_id])

    # if lesson.type_lesson == 1
    #   raise "#{lesson.address}"
    # end
  end

  def show
  end

  def new
  end

  def create
  end

  def update
  end

  def destroy
  end

end
