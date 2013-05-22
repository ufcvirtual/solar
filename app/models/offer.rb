class Offer < ActiveRecord::Base

  include Taggable

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :schedule

  has_many :groups
  has_many :assignments, :through => :allocation_tag

  validates :course, :presence => true
  validates :curriculum_unit, :presence => true
  validates :semester, :presence => true, :format => {:with => %r{^(\d{4}).(\d{1}*[1-2])} } # formato: 9999.1/.2
  validates :start_date, :presence => true
  validates :end_date, :presence => true
  
  validate :semester_must_be_unique
  validate :start_must_be_previous_than_end

  # modulo default da oferta
  after_create :set_default_lesson_module

  def has_any_lower_association?
    self.groups.count > 0
  end

  def lower_associated_objects
    groups
  end

  ##
  # Para um mesmo curso e uma mesma unidade curricular, o semestre deve ser único
  ##
  def semester_must_be_unique
    offers_with_same_semester = Offer.find_all_by_curriculum_unit_id_and_course_id_and_semester(curriculum_unit_id, course_id, semester)
    errors.add(:semester, I18n.t(:existing_semester, :scope => [:offers])) if (@new_record == true or semester_changed?) and offers_with_same_semester.size > 0
  end

  ##
  # Data inicial deve ser anterior à data final
  ##
  def start_must_be_previous_than_end
    unless start_date.nil? or end_date.nil?
      errors.add(:start_date, I18n.t(:range_date_error, :scope => [:offers])) if (start_date > end_date)
    end
  end

  ##
  # Retorna as informações da schedule da oferta (período de matrícula)
  ##
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

end
