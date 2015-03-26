class ExamQuestion < ActiveRecord::Base

  belongs_to :question
  belongs_to :exam
end
