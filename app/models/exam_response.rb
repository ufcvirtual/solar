class ExamResponse < ActiveRecord::Base

  belongs_to :exam_user
  belongs_to :question_item
  
  has_one :user    , through: :exam_user
  has_one :question, through: :question_item

end
