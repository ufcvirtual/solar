module LessonsHelper

  def files_and_folders(lesson)
    file = lesson.path(true, false).to_s

    @files = directory_hash(file, lesson.name).to_json
    @folders = directory_hash(file, lesson.name, false).to_json
  end

end
