class Offer < ActiveRecord::Base

  include Taggable

  belongs_to :course
  belongs_to :curriculum_unit

  belongs_to :semester
  belongs_to :offer_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  has_many :groups
  has_many :assignments, through: :allocation_tag

  validates :course, presence: true, if: "curriculum_unit.nil?"
  validates :curriculum_unit, presence: true, if: "course.nil?"
  validates :semester, presence: true

  # validate :semester_must_be_unique

  after_create :set_default_lesson_module # modulo default da oferta

  after_destroy { |record|
    record.offer_schedule.destroy if record.offer_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  def has_any_lower_association?
    self.groups.count > 0
  end

  def lower_associated_objects
    groups
  end

  # def semester_must_be_unique
  #   offers_with_same_semester = Offer.find_all_by_curriculum_unit_id_and_course_id_and_semester(curriculum_unit_id, course_id, semester)
  #   errors.add(:semester, I18n.t(:existing_semester, :scope => [:offers])) if (@new_record == true or semester_changed?) and offers_with_same_semester.size > 0
  # end

  #
  # tirar dos locales: I18n.t(:range_date_error, :scope => [:offers])
  #

  ## Retorna as informações da schedule da oferta (período de matrícula)
  def schedule_info
    schedule_dates = []
    schedule_dates << I18n.l(self.schedule.start_date, format: :normal)
    schedule_dates << (self.schedule.end_date.nil? ? I18n.t(:no_end_date, scope: :offers) : I18n.l(self.schedule.end_date, format: :normal))
    schedule_dates = schedule_dates.join(" - ") 
    is_active      = (self.schedule.start_date <= Time.now and (self.schedule.end_date.nil? or self.schedule.end_date >= Time.now))

    return {"schedule_dates" => schedule_dates, "is_active" => is_active}
  end

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_offer, scope: :lesson_modules))
  end

  ## datas da oferta

  def start_date
    offer_schedule.try(:start_date) || semester.offer_schedule.start_date
  end

  def end_date
    offer_schedule.try(:end_date) || semester.offer_schedule.end_date
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
