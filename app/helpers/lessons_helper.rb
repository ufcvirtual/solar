module LessonsHelper

  def files_and_folders(lesson)
    file = lesson.path(true, false).to_s
    @files   = directory_hash(file, lesson.name).to_json
    @folders = directory_hash(file, lesson.name, false).to_json
  end

  def mobile_device?
	  if session[:mobile_param]
	    session[:mobile_param] == "1"
	  else
	    request.user_agent =~ /Mobile|webOS/
	  end
	end

	def get_audio(lesson_id, main=nil)
		if main.nil?
			LessonAudio.where(lesson_id: lesson_id,  status: true)
		else
			LessonAudio.where(lesson_id: lesson_id, main: true,  status: true).first
		end	
	end

end
