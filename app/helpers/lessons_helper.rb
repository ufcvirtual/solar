module LessonsHelper

  def files_and_folders(lesson)
    file = lesson.path(true, false).to_s
    @files   = directory_hash(file, lesson.name).to_json
    @folders = directory_hash(file, lesson.name, false).to_json
  end

  def get_audio(lesson_id, main=nil)
		if main.nil?
			LessonAudio.where(lesson_id: lesson_id)
		else
			LessonAudio.where(lesson_id: lesson_id, main: true).first
		end	
	end

end
