class ExamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation

  has_many :exam_response, dependent: :destroy
end
