class ExamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation

  has_many :exam_responses, dependent: :destroy
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items

end
