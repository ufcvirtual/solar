class ExamResponse < ActiveRecord::Base

  belongs_to :exam_user
  has_and_belongs_to_many :question_items

  
  has_one :user    , through: :exam_user
  has_one :question, through: :question_item

  def self.is_unique?(er)
    er.question_items.count == 1
  end

  def self.get_question_item_id(er)
   er.question_items.first.id
  end
end
