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

  def self.academic_allocations_by_ats(allocation_tags_ids, page: 1, per_page: 30)
    AcademicAllocation.select('DISTINCT ON (academic_tool_id) *').joins(:exam)
        .where(allocation_tag_id: allocation_tags_ids)
        .order(:academic_tool_id)
        .paginate(page: page, per_page: per_page)
  end
end
