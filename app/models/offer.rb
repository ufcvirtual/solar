class Offer < ActiveRecord::Base
  include Taggable

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
  has_many :log_navigations
  after_create :set_default_lesson_module # modulo default da oferta

  before_destroy :can_destroy?

  after_destroy { |record|
    record.period_schedule.destroy     if record.period_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  validates :course, presence: true, if: "curriculum_unit.nil?"
  validates :curriculum_unit, presence: true, if: "course.nil?"
  validates :semester, presence: true

  validate :define_curriculum_unit, if: "!course.nil? && type_id == 3"
  validate :check_period, :must_be_unique

  accepts_nested_attributes_for :period_schedule, :enrollment_schedule, reject_if: proc { |s| s[:start_date].blank? && s[:end_date].blank? }, allow_destroy: true

  after_save :update_digital_class, if: "curriculum_unit_id_changed? || course_id_changed? || semester_id_changed?"

  attr_accessor :type_id, :verify_current_date

  def must_be_unique
    equal_offers = Offer.find_all_by_course_id_and_curriculum_unit_id_and_semester_id(course_id, curriculum_unit_id, semester_id)
    errors_to = (type_id == 3 ? :course : :curriculum_unit_id)
    errors.add(errors_to, I18n.t(:already_exist, scope: [:offers, :error])) if (@new_record && equal_offers.size > 0) || ((!equal_offers.empty?) && equal_offers.first.try(:id) != self.id)
  end

  def define_curriculum_unit
    course          = Course.find(course_id)
    curriculum_unit = CurriculumUnit.find_by_name_and_code(course.try(:name), course.try(:code))
    self.curriculum_unit_id = curriculum_unit.try(:id)
  end

  def check_period
    self.period_schedule.check_end_date = true if period_schedule && period_schedule.start_date
    unless verify_current_date == false
      self.period_schedule.verify_current_date     = true if period_schedule && (get_start_date != self.period_schedule.start_date)
      self.enrollment_schedule.verify_current_date = true if enrollment_schedule
    end
  end

  def any_lower_association?
    groups.any?
  end

  def get_start_date
    of = Offer.find(self.id)
    if of.offer_schedule_id
      start_date = Schedule.find(of.offer_schedule_id).start_date
    else
      id = Semester.find(of.semester_id).offer_schedule_id
      start_date = Schedule.find(id).start_date
    end
    start_date  
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
    if enrollment_schedule_id.nil? || enrollment_schedule.end_date.nil? # se o periodo de matricula na oferta for nulo
      end_date
    else
      enrollment_schedule.end_date
    end
  end

  def enrollment_period
    [enrollment_start_date, enrollment_end_date]
  end

  def self.currents(opt = { year: nil, object: false, user_id: nil, profiles: nil, verify_end_date: nil })
    opt[:year] = (opt[:year] ? Date.parse("#{opt[:year]}-01-01") : Date.today) unless opt[:year].class == Date

    options    = { date: (opt[:year].nil? ? Date.today : opt[:year]), start_of_year: (opt[:year].nil? ? Date.today.beginning_of_year : opt[:year].beginning_of_year), end_of_year: (opt[:year].nil? ? nil : opt[:year].end_of_year), user_id: opt[:user_id] }
    # query      = ((opt[:year].nil?) ? "((schedules.end_date BETWEEN :start_of_year AND :end_of_year) OR (schedules.end_date >= :end_of_year))" : ":date <= schedules.end_date")
    query      = ((opt[:year].nil?) ? "((schedules.end_date BETWEEN :start_of_year AND :end_of_year) OR (schedules.start_date BETWEEN :start_of_year AND :end_of_year) OR (schedules.start_date <= :start_of_year AND schedules.end_date >= :end_of_year))" : ":date <= schedules.end_date")
    rts        = RelatedTaggable.joins(:schedule).where(query, options.slice(:date, :start_of_year, :end_of_year))

    query = (opt[:profiles] ? "allocations.profile_id IN (?)" : "")
    rts   = rts.joins("JOIN allocations ON (related_taggables.group_at_id = allocations.allocation_tag_id OR related_taggables.offer_at_id = allocations.allocation_tag_id 
      OR related_taggables.course_at_id = allocations.allocation_tag_id OR related_taggables.curriculum_unit_at_id = allocations.allocation_tag_id 
      OR related_taggables.curriculum_unit_type_at_id = allocations.allocation_tag_id)").where(allocations: {user_id: opt[:user_id], status: Allocation_Activated}).where(query, opt[:profiles]) if opt[:user_id]

    query = []
    query << "related_taggables.curriculum_unit_id = :curriculum_unit_id"  if opt[:curriculum_unit_id].present?
    query << "related_taggables.course_id = :course_id"                    if opt[:course_id].present?
    query << "related_taggables.curriculum_unit_type_id = :curriculum_unit_type_id" if opt[:curriculum_unit_type_id].present?
    rts = rts.where(query.join(" AND "), opt.slice(:curriculum_unit_id, :course_id, :curriculum_unit_type_id)) if query.any?
      

    ids = rts.pluck(:offer_id).uniq
    opt[:object] ? where(id: ids) : ids
  end 

  def has_any_lower_association?
    self.groups.count > 0
  end

  def detailed_info
    {
      curriculum_unit_type: curriculum_unit_type.try(:description) || '',
      curriculum_unit_type_id: curriculum_unit_type.try(:id) || '',
      course: course.try(:name) || '',
      curriculum_unit: curriculum_unit.try(:name) || '',
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
    Offer.find_by_sql <<-SQL
      WITH profiles AS (
        SELECT profile_id
        FROM resources
        JOIN permissions_resources ON resources.id = permissions_resources.resource_id 
        WHERE resources.action = 'show' AND resources.controller = 'curriculum_units'
      ), logs AS (
        SELECT DISTINCT id
        FROM log_accesses
        WHERE log_accesses.user_id = #{user.id} 
        AND log_type = #{LogAccess::TYPE[:group_access]}
        AND log_accesses.created_at >= (current_date - interval '3 weeks')
      )
      SELECT DISTINCT rt.offer_at_id  AS at_id,
             rt.offer_id              AS offer_id,
             semesters.name           AS s_name, 
             courses.code             AS c_code, 
             courses.name             AS c_name, 
             curriculum_units.code    AS uc_code, 
             curriculum_units.name    AS uc_name,
             curriculum_unit_types.id AS uc_type_id,
             COUNT(DISTINCT log_accesses.id) AS accesses,
             curriculum_unit_types.description AS uc_type,
             curriculum_unit_types.icon_name   AS uc_type_icon,
             array_agg('X' || allocations.profile_id || 'X') AS profiles
      FROM related_taggables rt
           JOIN groups                ON groups.id = rt.group_id
      LEFT JOIN offers                ON offers.id = rt.offer_id
      LEFT JOIN curriculum_units      ON curriculum_units.id = rt.curriculum_unit_id
      LEFT JOIN curriculum_unit_types ON curriculum_unit_types.id = rt.curriculum_unit_type_id
      LEFT JOIN courses               ON courses.id = rt.course_id
      LEFT JOIN semesters             ON semesters.id = rt.semester_id
      LEFT JOIN schedules             ON schedules.id = rt.offer_schedule_id
      LEFT JOIN log_accesses          ON log_accesses.allocation_tag_id = rt.group_at_id AND log_accesses.id IN (select id from logs)
      JOIN allocations                ON (allocations.allocation_tag_id = rt.group_at_id OR allocations.allocation_tag_id = rt.offer_at_id OR allocations.allocation_tag_id = rt.course_at_id OR allocations.allocation_tag_id = rt.curriculum_unit_at_id OR allocations.allocation_tag_id = rt.curriculum_unit_type_at_id) AND allocations.user_id = #{user.id} AND allocations.status = #{Allocation_Activated} AND allocations.profile_id IN (select profile_id from profiles)
      WHERE
        group_status = true AND groups.id IS NOT NULL AND current_date <= schedules.end_date AND allocations.status = #{Allocation_Activated}
        GROUP BY offer_at_id, rt.offer_id, semesters.name, courses.code, courses.name, curriculum_units.code,curriculum_units.name, curriculum_unit_types.description, curriculum_unit_types.id, curriculum_unit_types.icon_name
        ORDER BY accesses DESC, s_name DESC, uc_name ASC;
    SQL
  end

  # offers.*, enroll_start_date, enroll_end_date
  def self.to_enroll
    find_by_sql <<-SQL
      SELECT o.*, COALESCE(os_e.start_date, ss_e.start_date)::date AS enroll_start_date,
        CASE
          WHEN o.enrollment_schedule_id IS NULL THEN COALESCE(ss_e.end_date, ss_p.end_date)::date
          WHEN o.enrollment_schedule_id IS NOT NULL AND o.offer_schedule_id IS NULL THEN COALESCE(os_e.end_date, ss_p.end_date)::date
          ELSE COALESCE(os_e.end_date, os_p.end_date, ss_e.end_date, ss_p.end_date)::date
        END AS enroll_end_date
        FROM offers                 AS o
        JOIN semesters              AS s    ON s.id    = o.semester_id
        JOIN schedules              AS ss_e ON ss_e.id = s.enrollment_schedule_id -- periodo de matricula do semestre
        JOIN schedules              AS ss_p ON ss_p.id = s.offer_schedule_id -- periodo do semestre
        LEFT JOIN curriculum_units       AS uc   ON uc.id = o.curriculum_unit_id
        LEFT JOIN curriculum_unit_types  AS ct   ON ct.id = uc.curriculum_unit_type_id
        LEFT JOIN courses           AS c         ON c.id = o.course_id
   LEFT JOIN schedules              AS os_e ON os_e.id = o.enrollment_schedule_id -- periodo de matricula definido na oferta
   LEFT JOIN schedules              AS os_p ON os_p.id = o.offer_schedule_id -- periodo da oferta
       WHERE
          ((ct.id IS NULL AND c.id IS NOT NULL) OR (ct.allows_enrollment IS TRUE))
          AND (
            -- periodo de matricula informado na oferta
            (
              o.enrollment_schedule_id IS NOT NULL AND (

                -- matricula definida na oferta com data final
                (
                  os_e.end_date IS NOT NULL
                  AND
                  current_date BETWEEN os_e.start_date AND os_e.end_date -- final de matricula na oferta
                )

                -- matricula definida na oferta, mas sem data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NOT NULL
                  AND
                  current_date BETWEEN os_e.start_date AND os_p.end_date -- final de matricula no periodo da oferta
                )

                -- matricula definida na oferta sem data final
                OR
                (
                  os_e.end_date IS NULL AND o.offer_schedule_id IS NULL
                  AND
                  current_date BETWEEN os_e.start_date AND ss_p.end_date -- final de matricula no periodo do semestre
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
                    current_date BETWEEN ss_e.start_date AND ss_e.end_date -- usa periodo de matricula
                  )

                  OR

                  (
                    ss_e.end_date IS NULL
                    AND
                    current_date BETWEEN ss_e.start_date AND ss_p.end_date -- usa data final do periodo
                  )
                )
              )
            )

          ) -- and
        ORDER BY enroll_start_date DESC;
    SQL
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

  ## triggers

  # trigger.after(:update) do
  trigger.after(:update).of(:curriculum_unit_id, :course_id, :semester_id, :offer_schedule_id) do
    <<-SQL

      -- curriculum unit id
      IF NEW.curriculum_unit_id <> OLD.curriculum_unit_id THEN
        UPDATE related_taggables
           SET curriculum_unit_id = NEW.curriculum_unit_id,
               curriculum_unit_at_id = (SELECT id FROM allocation_tags WHERE curriculum_unit_id = NEW.curriculum_unit_id)
         WHERE offer_id = OLD.id;
      END IF;

      -- course
      IF NEW.course_id <> OLD.course_id THEN
        UPDATE related_taggables
           SET course_id = NEW.course_id,
               course_at_id = (SELECT id FROM allocation_tags WHERE course_id = NEW.course_id)
         WHERE offer_id = OLD.id;
      END IF;

      IF NEW.semester_id <> OLD.semester_id THEN
        UPDATE related_taggables
           SET semester_id = NEW.semester_id
         WHERE offer_id = OLD.id;
      END IF;

      -- offer shedule
      IF NEW.offer_schedule_id <> OLD.offer_schedule_id OR (NEW.offer_schedule_id IS NULL) <> (OLD.offer_schedule_id IS NULL) THEN
        IF NEW.offer_schedule_id IS NULL THEN
          -- se setar null tem q mudar para o schedule para o do semestre
          UPDATE related_taggables
             SET offer_schedule_id = (SELECT offer_schedule_id FROM semesters WHERE id = NEW.semester_id)
           WHERE offer_id = OLD.id;
        ELSE
          UPDATE related_taggables
             SET offer_schedule_id = NEW.offer_schedule_id
           WHERE offer_id = OLD.id;
        END IF;

      END IF;

    SQL
  end

end
