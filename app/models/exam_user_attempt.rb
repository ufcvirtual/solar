class ExamUserAttempt < ActiveRecord::Base

  belongs_to :academic_allocation_user
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Exam' }

  has_one :exam, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation_user
  has_one :user, through: :academic_allocation_user

  has_many :exam_responses, dependent: :destroy
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true }

  def copy_dependencies_from(attempt)
    unless attempt.exam_responses.empty?
      attempt.exam_responses.each do |response|
        new_response = ExamResponse.where(response.attributes.except('id').merge!({ exam_user_attempt_id: self.id })).first_or_create
        response.question_items.each do |item|
          new_response.question_items << item
        end
        new_response.save
      end
    end
  end

  def delete_with_dependents
    exam_responses.delete_all
    self.delete
  end

  def get_total_time
    exam_responses.sum(:duration)
  end

  def uninterrupted_or_ended(exam)
    ((exam_responses.present? && exam.uninterrupted?) || exam.ended?)
  end

end
