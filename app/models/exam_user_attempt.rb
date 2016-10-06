class ExamUserAttempt < ActiveRecord::Base

  belongs_to :academic_allocation_user
  belongs_to :academic_allocation, conditions: { academic_tool_type: 'Exam' }

  has_one :exam, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation_user
  has_one :user, through: :academic_allocation_user

  has_many :exam_responses, dependent: :destroy
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items
  has_many :exam_responses_question_items, through: :exam_responses

  validates :grade, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_blank: true }

  def copy_dependencies_from(attempt)
    unless attempt.exam_responses.empty?
      attempt.exam_responses.each do |response|
        new_response = ExamResponse.where(response.attributes.except('id').merge!({ exam_user_attempt_id: self.id })).first_or_create
        response.exam_responses_question_items.each do |item|
          new_item = ExamResponsesQuestionItem.where(exam_response_id: item.exam_response_id, question_item_id: item.question_item_id).first_or_initialize
          new_item.value = item.value
        end
        new_response.save
      end
    end
  end

  def delete_with_dependents
    exam_responses.delete_all
    self.delete
  end

  def get_total_time(er_id=nil, time=nil)
    if time.blank? || er_id.blank?
      exam_responses.sum(:duration)
    else
      exam_responses.where("id != #{er_id}").sum(:duration) + time
    end
  end

  def uninterrupted_or_ended(exam)
    ((exam_responses.present? && exam.uninterrupted?) || exam.ended?)
  end

end
