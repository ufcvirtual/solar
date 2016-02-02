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
    attempts = exam_user_attempts.where(complete: true)
    grade = case exam.attempts_correction
            when Exam::GREATER; attempts.map(&:grade).max
            when Exam::AVERAGE then 
              grades = attempts.map(&:grade)
              grades.inject{ |sum, el| sum + el }.to_f / grades.size
            when Exam::LAST; attempts.last.grade
            end
    { grade: grade, complete: attempts.any? }
  end

  def delete_with_dependents
    exam_user_attempts.delete_with_dependents
    self.delete
  end

end
