class ExamResponse < ActiveRecord::Base

  belongs_to :exam_user
  has_and_belongs_to_many :question_items

  
  has_one :user    , through: :exam_user
  has_one :question, through: :question_item

end
