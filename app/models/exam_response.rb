class ExamResponse < ActiveRecord::Base

  belongs_to :exam_user_attempt
  belongs_to :question
  has_many :exam_responses_question_items
  has_many :question_items, through: :exam_responses_question_items
  
  has_one :academic_allocation_user, through: :exam_user_attempt
  has_one :user    , through: :academic_allocation_user

  accepts_nested_attributes_for :exam_responses_question_items

  validates :unique, if: 'question.type_question == 0'

  def unique
    errors.add(:base, I18n.t('exams.error.unique_choice')) if question.type_question == Question::UNIQUE && exam_responses_question_items.where(value: true).count > 1
  end

  def self.is_unique?(er)
    er.question_items.count == 1
  end

  def self.get_question_item_id(er)
   er.question_items.first.id
  end
end
