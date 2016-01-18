module ExamsHelper

  def grade(exam_id)    
    exam = ExamUser.where(academic_allocation_id: exam_id, user_id: current_user.id)
    unless exam.nil? || exam.empty?
    	return exam.grade
    end
    return '-'
  end

  def status(exam_id)
    exam = ExamUser.where(academic_allocation_id: exam_id, user_id: current_user.id)
    unless exam.nil? || exam.empty?
    	exam.complete? ? I18n.t(:ended) : I18n.t(:not_ended)
    end
    return I18n.t(:not_started)
  end

  def get_items(question_id)
    QuestionItem.list(question_id)
  end

  def get_question_images(question_id)
    QuestionImage.list(question_id)
  end

  def get_image_size (count)
    case count
      when 1
        :large
      when 2
        :medium
      else
        :small
    end
  end

end