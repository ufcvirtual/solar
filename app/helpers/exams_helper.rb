module ExamsHelper

  def grade(exam_id)
    exam = ExamUser.where(academic_allocation_id: exam_id, user_id: current_user.id)
    unless exam.nil? || exam.empty?
    	return exam.grade.round(2)
    end
    return '-'
  end

  def get_question_images(question_id)
    QuestionImage.list(question_id)
  end
  def get_question_audios(question_id)
    QuestionAudio.list(question_id)
  end

  def get_image_size(count)
    case count
      when 1
        :large
      when 2
        :medium
      else
        :small
    end
  end

  def find_exam_responses(last_attempt, question_id)
    last_attempt.exam_responses.where(question_id: question_id).first
  end

  def link_to_add_fields(name, f, association, html_options={})
    new_object = f.object.class.reflect_on_association(association).klass.new

    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render("exams/form/" + association.to_s.singularize + "_fields", :f => builder)
    end

    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", html_options)
  end

  def link_to_remove_fields(name, f, html_options={})
    link_to_function(name, "remove_fields(this)", html_options)
  end

end
