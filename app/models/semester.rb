class Semester < ActiveRecord::Base
  has_many :offers

  belongs_to :offer_schedule, class_name: "Schedule", foreign_key: "offer_schedule_id"
  belongs_to :enrollment_schedule, class_name: "Schedule", foreign_key: "enrollment_schedule_id"

  validates :name, presence: true, uniqueness: true
  validates :enrollment_schedule, :offer_schedule, presence: true

  validate :check_period

  accepts_nested_attributes_for :offer_schedule, :enrollment_schedule

  attr_accessible :name, :offer_schedule_attributes, :enrollment_schedule_attributes

  after_destroy { |record|
    record.offer_schedule.destroy if record.offer_schedule.try(:can_destroy?)
    record.enrollment_schedule.destroy if record.enrollment_schedule.try(:can_destroy?)
  }

  def check_period
    self.offer_schedule.check_end_date, self.offer_schedule.verify_current_date = true, true if offer_schedule
    self.enrollment_schedule.verify_current_date = true if enrollment_schedule
  end

  def self.currents(year = nil)
    unless year # se o ano passado for nil, pega os semestres do ano corrente em endiante
      self.joins(:offer_schedule).where("schedules.end_date >= ?", Date.parse("#{Date.today.year}-01-01"))
    else # se foi definido, pega apenas daquele ano
      first_day_of_year, last_day_of_year = Date.parse("#{year}-01-01"), Date.parse("#{year}-12-31")
      self.joins(:offer_schedule).where("(schedules.end_date BETWEEN ? AND ?) OR (schedules.start_date BETWEEN ? AND ?)", first_day_of_year, last_day_of_year, first_day_of_year, last_day_of_year)
    end
  end

end
