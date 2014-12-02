class Notification < ActiveRecord::Base
  include AcademicTool
  include ActiveModel::ForbiddenAttributesProtection

  GROUP_PERMISSION = OFFER_PERMISSION = CURRICULUM_UNIT_PERMISSION = COURSE_PERMISSION = CURRICULUM_UNIT_TYPE_PERMISSION = true

  scope :active, -> { joins(:schedule).where("date(schedules.start_date) <= :today and date(schedules.end_date) >= :today", today: Date.today) }

  belongs_to :schedule

  has_and_belongs_to_many :users, join_table: 'read_notifications'
  has_many :read_notifications

  accepts_nested_attributes_for :schedule

  before_validation proc { self.schedule.check_end_date = true }, if: "schedule" # data final obrigatoria

  validates :title, :description, :schedule, presence: true
  validates :title, length: {maximum: 255}

  def period
    p = [I18n.l(start_date, format: :normal)]
    p << I18n.l(end_date, format: :normal) if end_date and end_date != start_date
    p.join(" - ")
  end

  def start_date
    schedule.start_date
  end

  def end_date
    schedule.end_date
  end

  def read?(user)
    read_notifications.where(user_id: user).any?
  end

  def mark_as_read(user)
    read_notifications.create(user: user) unless read?(user)
  end

  def self.of_user(user)
    active.select("notifications.*, rn.user_id AS read")
      .joins(:academic_allocations)
      .joins("LEFT JOIN read_notifications rn ON rn.notification_id = notifications.id AND rn.user_id = #{user.id}")
      .where(academic_allocations: {allocation_tag_id: user.all_allocation_tags})
      .order("read DESC, schedules.start_date DESC, schedules.end_date DESC")
  end

end
