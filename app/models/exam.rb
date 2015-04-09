class Exam < Event
  include AcademicTool

  GROUP_PERMISSION = true

  belongs_to :schedule

  has_many :exam_questions, dependent: :destroy
  has_many :questions, through: :exam_questions

  accepts_nested_attributes_for :schedule


  def self.my_exams(allocation_tag_id)
  	exams = Exam.joins(:academic_allocations, :schedule)
      .where(academic_allocations: {allocation_tag_id: allocation_tag_id})
      .select('DISTINCT exams.*, schedules.start_date as start_date, schedules.end_date as end_date')
      .order('schedules.start_date')
  end

end
