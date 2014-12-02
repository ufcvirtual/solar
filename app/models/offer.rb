class Offer < ActiveRecord::Base
  include Taggable
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :course
  belongs_to :curriculum_unit
  belongs_to :semester

  belongs_to :period_schedule,      class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule,  class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  has_one :curriculum_unit_type, through: :curriculum_unit

  has_many :groups
  has_many :academic_allocations, through: :allocation_tag
  has_many :lesson_modules,       through: :academic_allocations, source: :academic_tool, source_type: "LessonModule"
  has_many :assignments,          through: :academic_allocations, source: :academic_tool, source_type: "Assignment"

  after_create :set_default_lesson_module # modulo default da oferta

  before_destroy :can_destroy?

  after_destroy { |record|
    record.period_schedule.destroy if record.period_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  validates :course, presence: true, if: "curriculum_unit.nil?"
  validates :curriculum_unit, presence: true, if: "course.nil?"
  validates :semester, presence: true

  validate :define_curriculum_unit, if: "!course.nil? && type_id == 3"
  validate :check_period, :must_be_unique

  accepts_nested_attributes_for :period_schedule, :enrollment_schedule, reject_if: proc { |s| s[:start_date].blank? and s[:end_date].blank? }, allow_destroy: true

  attr_accessor :type_id, :verify_current_date

  def must_be_unique
    equal_offers = Offer.find_all_by_course_id_and_curriculum_unit_id_and_semester_id(course_id, curriculum_unit_id, semester_id)
    errors_to = (type_id == 3 ? :course : :curriculum_unit_id)
    errors.add(errors_to, I18n.t(:already_exist, scope: [:offers, :error])) if (@new_record and equal_offers.size > 0) or ((not equal_offers.empty?) and equal_offers.first.try(:id) != self.id)
  end

  def define_curriculum_unit
    course          = Course.find(course_id)
    curriculum_unit = CurriculumUnit.find_by_name_and_code(course.try(:name), course.try(:code))
    self.curriculum_unit_id = curriculum_unit.try(:id)
  end

  def check_period
    self.period_schedule.check_end_date = true if period_schedule and period_schedule.start_date
    unless verify_current_date == false
      self.period_schedule.verify_current_date = true if period_schedule
      self.enrollment_schedule.verify_current_date = true if enrollment_schedule
    end
  end

  def lower_associated_objects
    groups
  end

  def can_destroy?
    lower_associated_objects.empty?
  end

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
    if enrollment_schedule_id.nil? or enrollment_schedule.end_date.nil? # se o periodo de matricula na oferta for nulo
      semester.enrollment_schedule.end_date || semester.offer_schedule.end_date # o periodo no semestre será utilizado
    else
      enrollment_schedule.end_date
    end
  end

  def enrollment_period
    [enrollment_start_date, enrollment_end_date]
  end

  def self.currents(year = nil, verify_end_date = nil)
    unless year.class == Date
      year = Date.parse("#{year}-01-01") rescue Date.today
    end

    offers = joins(:period_schedule).includes(:allocation_tag)
    offers = unless year # se o ano passado for nil, pega as ofertas do ano corrente em diante
      first_day_of_year = Date.today.beginning_of_year
      offers.where("schedules.end_date >= ?", first_day_of_year)
    else # se foi definido, pega apenas daquele ano
      if verify_end_date
        offers.where("( schedules.end_date >= ? )", year)
      else
        last_day_of_year, first_day_of_year = year.end_of_year, year.beginning_of_year
        offers.where("(schedules.end_date BETWEEN ? AND ?) OR (schedules.start_date BETWEEN ? AND ?) OR (schedules.start_date <= ? AND schedules.end_date >= ?)",
          first_day_of_year, last_day_of_year, first_day_of_year, last_day_of_year, first_day_of_year, last_day_of_year)
      end
    end

    # recupera as ofertas que mantem a data do semestre ativo
    c_s = Semester.currents(year, verify_end_date).pluck(:id)
    current_semester_offers = joins(:semester).where(semesters: {id: c_s}).where("offers.offer_schedule_id IS NULL").pluck(:id) # period schedule is null

    where(id: [current_semester_offers, offers.pluck(:id)].flatten)
  end

  def has_any_lower_association?
    self.groups.count > 0
  end

  def detailed_info
    {
      curriculum_unit_type: curriculum_unit_type.try(:description),
      curriculum_unit_type_id: curriculum_unit_type.try(:id),
      course: course.try(:name),
      curriculum_unit: curriculum_unit.try(:name),
      semester: semester.name
    }
  end

  def is_active?
    Date.today <= end_date
  end

  def parent_name
    curriculum_unit.nil? ? course.name : curriculum_unit.name
  end

  ##
  # Returns user's offers which are current in the following order:
  # More accesses on the last 3 weeks > Have groups > Offer name ASC
  ##
  def self.offers_info_from_user(user)
    currents   = Offer.currents(Date.today, true)
    u_profiles = user.profiles_with_access_on("show", "curriculum_units", nil, true)
    # u_offers   = AllocationTag.includes(:offer).where(id: user.allocations.where(status: Allocation_Activated, profile_id: u_profiles).uniq.pluck(:allocation_tag_id)).map(&:offers).flatten.compact
    u_offers   = user.allocations.where(status: Allocation_Activated, profile_id: u_profiles).map(&:offers).flatten.compact
    offers     = (currents & u_offers)

    allocations_info = offers.collect{ |offer|
      ats = offer.allocation_tag.related
      uc, course = offer.curriculum_unit, offer.course
        {
          id: offer.id,
          info: offer.allocation_tag.info,
          at: offer.allocation_tag.id,
          related: offer.allocation_tag.related,
          name: (uc.nil? ? course.name.titleize : uc.name.titleize),
          has_groups: not(offer.groups.empty?),
          uc: uc,
          course: course,
          semester_name: offer.semester.name,
          profiles: user.allocations.includes(:profile).where("allocation_tag_id IN (?)", ats).select("DISTINCT profile_id, allocations.*").map(&:profile).map(&:id).uniq.join(", ")
        }
    }.flatten

    allocations_info.sort_by! do |allocation|
      allocation[:name]
      allocation[:has_groups]
      -(LogAccess.count(:id, conditions: {log_type: LogAccess::TYPE[:group_access], user_id: user.id,
        allocation_tag_id: allocation[:related], created_at: 3.week.ago..Time.now}))
    end

    return allocations_info
  end

  # offers.*, enroll_start_date, enroll_end_date
  def self.to_enroll
    find_by_sql %{
      SELECT o.*, COALESCE(os_e.start_date, ss_e.start_date)::date AS enroll_start_date,
        CASE
          WHEN o.enrollment_schedule_id IS NULL THEN COALESCE(ss_e.end_date, ss_p.end_date)::date
          WHEN o.enrollment_schedule_id IS NOT NULL AND o.offer_schedule_id IS NULL THEN COALESCE(os_e.end_date, ss_e.end_date, ss_p.end_date)::date
          ELSE COALESCE(os_e.end_date, os_p.end_date, ss_e.end_date, ss_p.end_date)::date
        END AS enroll_end_date
        FROM offers                 AS o
        JOIN semesters              AS s    ON s.id    = o.semester_id
        JOIN schedules              AS ss_e ON ss_e.id = s.enrollment_schedule_id -- periodo de matricula do semestre
        JOIN schedules              AS ss_p ON ss_p.id = s.offer_schedule_id -- periodo do semestre
        JOIN curriculum_units       AS uc   ON uc.id = o.curriculum_unit_id
        JOIN curriculum_unit_types  AS ct   ON ct.id = uc.curriculum_unit_type_id
   LEFT JOIN schedules              AS os_e ON os_e.id = o.enrollment_schedule_id -- periodo de matricula definido na oferta
   LEFT JOIN schedules              AS os_p ON os_p.id = o.offer_schedule_id -- periodo da oferta
       WHERE
          ct.allows_enrollment IS TRUE
          AND (
            -- periodo de matricula informado na oferta
            (
              o.enrollment_schedule_id IS NOT NULL AND (

                -- matricula definida na oferta com data final
                (
                  os_e.end_date IS NOT NULL
                  AND
                  now() BETWEEN os_e.start_date AND os_e.end_date -- final de matricula na oferta
                )

                -- matricula definida na oferta, mas sem data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NOT NULL
                  AND
                  now() BETWEEN os_e.start_date AND os_p.end_date -- final de matricula no periodo da oferta
                )

                -- matricula definida na oferta sem data final e semestre possui matricula com data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NULL AND ss_e.end_date IS NOT NULL
                  AND
                  now() BETWEEN os_e.start_date AND ss_e.end_date -- final de matricula na matricula do semestre
                )

                -- matricula definida na oferta sem data final e semestre possui matricula sem data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NULL AND ss_e.end_date IS NULL
                  AND
                  now() BETWEEN os_e.start_date AND ss_p.end_date -- final de matricula no periodo do semestre
                )
              )

              OR

              -- periodo de matricula nao informado na oferta
              (
                o.enrollment_schedule_id IS NULL AND (
                  -- semestre possui matricula com data final
                  (
                    ss_e.end_date IS NOT NULL
                    AND
                    now() BETWEEN ss_e.start_date AND ss_e.end_date -- usa periodo de matricula
                  )

                  OR

                  (
                    ss_e.end_date IS NULL
                    AND
                    now() BETWEEN ss_e.start_date AND ss_p.end_date -- usa data final do periodo
                  )
                )
              )
            )

          ) -- and
        ORDER BY enroll_start_date DESC;
    }
  end

  def notify_editors_of_disabled_groups(groups)
    emails = users_with_profile_type(Profile_Type_Editor).map(&:email)
    emails << groups.map { |group| group.users_with_profile_type(Profile_Type_Editor).map(&:email) }

    offer_info = info # nao colocar objetos AR dentro de threads
    group_codes = groups.map(&:code).join(', ')

    Thread.new do
      Notifier.groups_disabled(emails.flatten.uniq.join(", "), group_codes, offer_info).deliver
    end
  end

end
