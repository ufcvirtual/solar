class ExamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Exam' }

  has_one :exam,     through: :academic_allocation
  has_one :allocation_tag, through: :academic_allocation

  has_many :exam_user_attempts, dependent: :destroy
  has_many :exam_responses, through: :exam_user_attempts
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items

  attr_accessor :merge

  def info
    complete_attempts = exam_user_attempts.where(complete: true)

    total_attempts = exam_user_attempts.count
    last_attempt = exam_user_attempts.last
    responses = last_attempt ? last_attempt.exam_responses.count : 0
    grade = case exam.attempts_correction
            when Exam::GREATER; complete_attempts.map(&:grade).max
            when Exam::AVERAGE then 
              grades = complete_attempts.map(&:grade)
              grades.inject{ |sum, el| sum + el }.to_f / grades.size
            when Exam::LAST; complete_attempts.last.grade
            end
    { grade: grade, complete: last_attempt, attempts: total_attempts, responses: responses }
  end

  def delete_with_dependents
    exam_user_attempts.map(&:delete_with_dependents)
    self.delete
  end

end
