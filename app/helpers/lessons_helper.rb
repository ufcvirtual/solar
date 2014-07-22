module LessonsHelper

  def lessons_by_module(lesson_module_id)
    Lesson.joins(:lesson_module, :schedule).where(lesson_modules: {id: lesson_module_id}).order("lessons.order")
  end

  def files_and_folders(lesson)
    file = lesson.path(true, false).to_s

    @files = directory_hash(file, lesson.name).to_json
    @folders = directory_hash(file, lesson.name, false).to_json
  end

end
