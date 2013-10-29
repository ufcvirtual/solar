class Notification < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION, CURRICULUM_UNIT_PERMISSION, COURSE_PERMISSION = true, true, true, true

  belongs_to :schedule

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  accepts_nested_attributes_for :schedule, allow_destroy: true

  before_validation proc { self.schedule.check_end_date = true } # data final obrigatoria

  validates :title, :description, presence: true
  validates :title, length: {maximum: 255}

  attr_accessible :title, :description, :schedule_attributes, :schedule_id

  def period
    p = [I18n.l(start_date, format: :normal)]
    p << I18n.l(end_date, format: :normal) if end_date
    p.join(" - ")
  end

  def start_date
    schedule.start_date
  end

  def end_date
    schedule.end_date
  end

end
