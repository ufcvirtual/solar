class ExamQuestion < ActiveRecord::Base

  belongs_to :question
  belongs_to :exam

  accepts_nested_attributes_for :question

  def self.list(exam_id)
  	ExamQuestion.joins(:question)
      .where(exam_questions: {exam_id: exam_id, annulled: false},
      	questions: {status: true})
      .select('DISTINCT exam_questions.question_id, exam_questions.score, exam_questions.order,
      	questions.id, questions.enunciation, questions.type_question')
      .order('exam_questions.order')
  end

end
