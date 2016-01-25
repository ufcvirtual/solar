class ExamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Exam' }

  has_one :exam,     through: :academic_allocation
  has_one :allocation_tag, through: :academic_allocation

  has_many :exam_responses, dependent: :destroy
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true }

  attr_accessor :merge

  def info
    grade, complete = try(:grade), try(:complete)
    { grade: grade, complete: complete }
  end

  def delete_with_dependents
    exam_responses.delete_all
    self.delete
  end

end
