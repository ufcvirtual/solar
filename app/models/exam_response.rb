class ExamResponse < ActiveRecord::Base

  include ControlledDependency

  belongs_to :exam_user_attempt
  belongs_to :question
  has_many :exam_responses_question_items, dependent: :destroy
  has_many :question_items, through: :exam_responses_question_items
  
  has_one :academic_allocation_user, through: :exam_user_attempt
  has_one :user    , through: :academic_allocation_user

  accepts_nested_attributes_for :exam_responses_question_items

  validate :unique, if: -> {question.type_question == 0}
  validate :arrow_last_answer_for_single_choice_questions

  def unique
    errors.add(:base, I18n.t('exams.error.unique_choice')) if question.type_question == Question::UNIQUE && exam_responses_question_items.where(value: true).count > 1
  end

  def self.is_unique?(er)
    er.question_items.count == 1
  end

  def self.get_question_item_id(er)
   er.question_items.first.id
  end

  def arrow_last_answer_for_single_choice_questions
    if question.type_question == Question::UNIQUE
      count_true = 0
      exam_responses_question_items.each{ |erqi|
        if erqi.value==true
          count_true = count_true + 1
        end
      }
      errors.add(:base, I18n.t('exams.error.unique_choice')) if count_true > 1
    end
  end
end
