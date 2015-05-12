class ExamQuestion < ActiveRecord::Base

  belongs_to :question
  belongs_to :exam

  accepts_nested_attributes_for :question
end
