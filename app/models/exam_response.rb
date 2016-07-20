class ExamResponse < ActiveRecord::Base

  belongs_to :exam_user_attempt
  has_and_belongs_to_many :question_items
  
  has_one :academic_allocation_user, through: :exam_user_attempt
  has_one :user    , through: :academic_allocation_user

  def self.is_unique?(er)
    er.question_items.count == 1
  end

  def self.get_question_item_id(er)
   er.question_items.first.id
  end
end
