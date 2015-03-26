class ExamResponse < ActiveRecord::Base

  belongs_to :exam_user
  belongs_to :question_item
end
