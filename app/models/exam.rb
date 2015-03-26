class Exam < Event
  include AcademicTool

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :exam_questions, dependent: :destroy
  has_many :questions, through: :exam_questions
end
