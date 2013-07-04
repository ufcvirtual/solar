class Offer < ActiveRecord::Base

  include Taggable

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :semester

  belongs_to :period_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  has_many :groups
  has_many :assignments, through: :allocation_tag

  after_create :set_default_lesson_module # modulo default da oferta
  after_destroy { |record|
    record.period_schedule.destroy if record.period_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  validates :course, presence: true, if: "curriculum_unit.nil?"
  validates :curriculum_unit, presence: true, if: "course.nil?"
  validates :semester, presence: true

  validate :check_period_end_date

  accepts_nested_attributes_for :period_schedule
  accepts_nested_attributes_for :enrollment_schedule

  attr_accessible :period_schedule_attributes, :enrollment_schedule_attributes, :curriculum_unit_id, :course_id, :semester_id

  def check_period_end_date
    self.period_schedule.check_end_date = true if period_schedule and period_schedule.start_date
  end

  def has_any_lower_association?
    self.groups.count > 0
  end

  def lower_associated_objects
    groups
  end

  #
  # tirar dos locales: I18n.t(:range_date_error, :scope => [:offers])
  #

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_offer, scope: :lesson_modules))
  end

  ## datas da oferta

  def start_date
    (period_schedule.try(:start_date) || semester.offer_schedule.start_date).to_date
  end

  def end_date
    (period_schedule.try(:end_date) || semester.offer_schedule.end_date).to_date
  end

  ## datas para matricula

  def enrollment_start_date
    enrollment_schedule.try(:start_date) || semester.enrollment_schedule.start_date
  end

  def enrollment_end_date
    # a oferta pode ou nao ter uma data final para periodo de matricula
    if enrollment_schedule_id.nil? # se o periodo de matricula na oferta for nulo
      semester.enrollment_schedule.end_date # o periodo no semestre será utilizado
    else
      enrollment_schedule.end_date
    end
  end

  def enrollment_period
    [enrollment_start_date, enrollment_end_date]
  end

end
