class Schedule < ActiveRecord::Base
  has_many :discussions
  has_many :lessons
  has_many :schedule_events
  has_many :assignments

  has_many :offer_periods, class_name: "Offer", foreign_key: "offer_schedule_id"
  has_many :offer_enrollments, class_name: "Offer", foreign_key: "enrollment_schedule_id"

  has_many :semester_periods, class_name: "Semester", foreign_key: "offer_schedule_id"
  has_many :semester_enrollments, class_name: "Semester", foreign_key: "enrollment_schedule_id"

  validates :start_date, presence: true
  validates :end_date, presence: true, if: "check_end_date"

  validate :start_date_before_end_date
  validate :verify_by_current_date, if: "verify_current_date" # mudar nome

  before_destroy :can_destroy?

  # check_end_date: caso esteja setado, a data final será obrigatória / verify_current_date: verifica se o período é válido dada a data/ano atual
  attr_accessor :check_end_date, :verify_current_date

  def start_date_before_end_date
    unless start_date.nil? or end_date.nil?
      errors.add(:start_date, I18n.t(:range_date_error, :scope => [:discussion, :errors])) if (start_date > end_date)
    end
  end

  def verify_by_current_date
    errors.add(:start_date, I18n.t(:current_year, :scope => [:schedules, :errors])) if not(start_date.nil?) and start_date_changed? and (start_date.year < Date.current.year)
    errors.add(:end_date, I18n.t(:current_date, :scope => [:schedules, :errors])) if not(end_date.nil?) and end_date_changed? and (end_date < Date.current)
  end

  def can_destroy?
    (discussions.empty? and lessons.empty? and assignments.empty? and schedule_events.empty? and offer_periods.empty? and offer_enrollments.empty? and semester_periods.empty? and semester_enrollments.empty?)
  end

  # Refazer esse metodo, devido a alterações na estrutura de Lessons, Discussions, Assignments(Ver Academic Allocation)
  def self.events(allocation_tags, period = false, date_search = nil)
    where, where_hash = [], {}
    where_date = []
    unless allocation_tags.nil?
      where_hash[:allocation_tags] = allocation_tags
      where << "allocation_tags.id IN (:allocation_tags)"
    end
    unless date_search.nil?
      where_hash[:date_search] = date_search.to_s(:db)

      where << "(schedules.start_date = :date_search OR schedules.end_date = :date_search)"
      where_hash_date = {}
      where_hash_date[:date_search] = date_search.to_s(:db)
      where_date = ["(schedules.start_date = :date_search OR schedules.end_date = :date_search)", where_hash_date]
    end

    where = [where.join(' AND '), where_hash]

    schedules_events   = ScheduleEvent.joins(:schedule, :allocation_tag).where(where).select("'schedule_events' AS schedule_type, schedule_events.title AS name, schedule_events.description, schedules.start_date, schedules.end_date")    
    discussions_events = Discussion.joins(:schedule, :allocation_tag).where(where).select("'discussions' AS schedule_type, discussions.name AS name, discussions.description, schedules.start_date, schedules.end_date")
    lessons_events     = Lesson.joins(:schedule, :allocation_tag).where(where).select("'lesson' AS schedule_type, lessons.name AS name, lessons.description, schedules.start_date, schedules.end_date")

    #SOLUÇÃO TEMPORÁRIA, enquanto nem todas as tabelas estão adaptadas a nova estrutura.
    unless allocation_tags.nil? 
      assignments_events = Assignment.joins(:schedule, :academic_allocations).where(academic_allocations: {allocation_tag_id: allocation_tags}).where(where_date).select("'assignments' AS schedule_type, assignments.name AS name, assignments.enunciation AS description, schedules.start_date, schedules.end_date")
    else
      assignments_events = Assignment.joins(:schedule, :academic_allocation).where(where_date).select("'assignments' AS schedule_type, assignments.name AS name, assignments.enunciation AS description, schedules.start_date, schedules.end_date")      
    end
    #SOLUÇÃO TEMPORÁRIA, enquanto nem todas as tabelas estão adaptadas a nova estrutura.

    events             = [schedules_events + assignments_events + discussions_events + lessons_events].flatten.compact.map(&:attributes).sort_by {|e| e['end_date'] || e['start_date'] }

    return events.slice(0,2) if period # apenas os dois primeiros
    return events
  end

end
