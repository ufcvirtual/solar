class Semester < ActiveRecord::Base
  include OfferSemester

  has_many :offers
  has_many :groups, through: :offers
  has_many :related_taggables

  belongs_to :offer_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  before_destroy :can_destroy?

  validates :name, presence: true, uniqueness: true
  validates :enrollment_schedule, :offer_schedule, presence: true

  validate :check_period

  accepts_nested_attributes_for :offer_schedule, :enrollment_schedule, allow_destroy: true

  after_save :update_digital_class, if: "name_changed?"

  attr_accessor :type_id, :verify_current_date

  after_destroy { |record|
    record.offer_schedule.destroy if record.offer_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  def check_period
    self.offer_schedule.verify_current_date = true if verify_current_date != false and offer_schedule
    self.offer_schedule.check_end_date, = true if offer_schedule
    self.enrollment_schedule.verify_current_date = true if enrollment_schedule and verify_current_date != false
  end

  def offers_by_allocation_tags(allocation_tags_ids, opts = {})
    offers.joins(:allocation_tag).joins('LEFT JOIN curriculum_units ON curriculum_units.id = offers.curriculum_unit_id').where(allocation_tags: {id: allocation_tags_ids}).where(opts.reject { |k,v| v.blank? })
  end

  def can_destroy?
    offers.empty? and groups.empty?
  end

  def self.currents(year = nil, verify_end_date = nil)
    date = Date.parse("#{year}-01-01") rescue Date.today unless year.class == Date

    semesters = joins(:offer_schedule)
    semesters = unless year # se o ano passado for nil, pega os semestres do ano corrente em endiante
      semesters.where("schedules.end_date >= ?", Date.today.beginning_of_year)
    else # se foi definido, pega apenas daquele ano
      if verify_end_date
        semesters.where("( schedules.end_date > ? )", year)
      else
        last_day_of_year, first_day_of_year = year.end_of_year, year.beginning_of_year
        semesters.where("(schedules.end_date BETWEEN ? AND ?) OR (schedules.start_date BETWEEN ? AND ?) OR (schedules.start_date <= ? AND schedules.end_date >= ?)", first_day_of_year, last_day_of_year, first_day_of_year, last_day_of_year, first_day_of_year, last_day_of_year)
      end
    end

  end

  def self.all_by_uc_or_course(params = {}, combobox=false)
    query = []
    query << ( (params[:course_id].blank? or params[:course_id] == "null") ? (combobox ? "offers.course_id IS NULL" : nil) : "offers.course_id = #{params[:course_id]}" )
    query << ( (params[:type_id] == 3 ? nil : (params[:uc_id].blank? or params[:uc_id] == "null") ? (combobox ? "offers.curriculum_unit_id IS NULL" : nil) : "offers.curriculum_unit_id = #{params[:uc_id]}") )
    query.compact!

    joins(:offers).where(query.join(" AND ")).uniq.order("name DESC")
  end

  def self.all_by_period(params = {}, combobox=false)
    query = []
    query << ( (params[:course_id].blank? or params[:course_id] == "null") ? (combobox ? "offers.course_id IS NULL" : nil) : "offers.course_id = #{params[:course_id]}" )
    query << ( (params[:type_id] == 3 ? nil : (params[:uc_id].blank? or params[:uc_id] == "null") ? (combobox ? "offers.curriculum_unit_id IS NULL" : nil) : "offers.curriculum_unit_id = #{params[:uc_id]}") )
    query.compact!

    year = Date.parse("#{params[:period]}-01-01") rescue Date.today

    current_semesters = Semester.joins("LEFT JOIN offers ON offers.semester_id = semesters.id").currents(year).where(query.join(" AND ")).uniq
    query << "semester_id NOT IN (#{current_semesters.map(&:id).join(',')})" unless current_semesters.empty? # retirando semestres ja listados
    semesters_of_current_offers = Offer.currents({year: year, object: true, curriculum_unit_type_id: params[:type_id], course_id: params[:course_id], curriculum_unit_id: params[:uc_id]}).where(query.join(" AND ")).map(&:semester)

    return (current_semesters + semesters_of_current_offers).uniq
  end

  def update_digital_class(ignore_changes=false)
    DigitalClass.update_taggable(self, ignore_changes) unless created_at_changed?
  end

end
