class ExamUserAttempt < ActiveRecord::Base

  belongs_to :exam_user
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Exam' }

  has_one :exam, through: :exam_user
  has_one :allocation_tag, through: :exam_user
  has_one :user, through: :exam_user

  has_many :exam_responses, dependent: :destroy
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true }

  attr_accessor :merge

  def delete_with_dependents
    exam_responses.delete_all
    self.delete
  end

end
