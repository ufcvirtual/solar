class Exam < Event
  include AcademicTool

  belongs_to :schedule

  has_many :exam_questions, dependent: :destroy
  has_many :questions, through: :exam_questions
end
