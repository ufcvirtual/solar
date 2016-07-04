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
end