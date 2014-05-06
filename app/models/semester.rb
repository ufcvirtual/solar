class Semester < ActiveRecord::Base
  has_many :offers

  belongs_to :offer_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  validates :name, presence: true, uniqueness: true
  validates :enrollment_schedule, :offer_schedule, presence: true

  validate :check_period

  accepts_nested_attributes_for :offer_schedule, :enrollment_schedule

  attr_accessible :name, :offer_schedule_attributes, :enrollment_schedule_attributes, :offer_schedule_id, :enrollment_schedule_id
  attr_accessor :verify_current_date

  after_destroy { |record|
    record.offer_schedule.destroy if record.offer_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  def check_period
    self.offer_schedule.verify_current_date = true if verify_current_date != false and offer_schedule
    self.offer_schedule.check_end_date, = true if offer_schedule
    self.enrollment_schedule.verify_current_date = true if enrollment_schedule and verify_current_date != false
  end

  def self.currents(year = nil)
    unless year # se o ano passado for nil, pega os semestres do ano corrente em endiante
      self.joins(:offer_schedule).where("schedules.end_date >= ?", Date.today.beginning_of_year)
    else # se foi definido, pega apenas daquele ano
      first_day_of_year, last_day_of_year = Date.today.beginning_of_year, Date.today.end_of_year
      self.joins(:offer_schedule).where("(schedules.end_date BETWEEN ? AND ?) OR (schedules.start_date BETWEEN ? AND ?)", first_day_of_year, last_day_of_year, first_day_of_year, last_day_of_year)
    end
  end

  def self.all_by_uc_or_course(params = {})
    query = []
    query << "offers.course_id = #{params[:course_id]}"      unless params[:course_id].blank? or params[:course_id] == "null"
    query << "offers.curriculum_unit_id = #{params[:uc_id]}" unless params[:uc_id].blank? or params[:uc_id] == "null"

    joins(:offers).where(query.join(" AND ")).uniq.order("name DESC")
  end

  def self.all_by_period(params = {})
    query = []
    query << "offers.course_id = #{params[:course_id]}" unless params[:course_id].blank?
    query << "offers.curriculum_unit_id = #{params[:uc_id]}" unless params[:uc_id].blank?

    begin
      year = Date.parse("#{params[:period]}-01-01").year
    rescue
      year = Date.today.year
    end

    current_semesters = Semester.joins("LEFT JOIN offers ON offers.semester_id = semesters.id").currents(year).where(query.join(" AND "))
    query << "semester_id NOT IN (#{current_semesters.map(&:id).join(',')})" unless current_semesters.empty? # retirando semestres ja listados
    semesters_of_current_offers = Offer.currents(year).where(query.join(" AND ")).map(&:semester)

    return (current_semesters + semesters_of_current_offers).uniq
  end

end
