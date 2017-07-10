class Notification < ActiveRecord::Base
  include AcademicTool

  GROUP_PERMISSION = OFFER_PERMISSION = CURRICULUM_UNIT_PERMISSION = COURSE_PERMISSION = CURRICULUM_UNIT_TYPE_PERMISSION = true

  scope :active, -> { joins(:schedule).where("date(schedules.start_date) <= :today and date(schedules.end_date) >= :today", today: Date.today) }

  belongs_to :schedule

  has_and_belongs_to_many :users, join_table: 'read_notifications'
  has_many :read_notifications

  accepts_nested_attributes_for :schedule

  before_validation proc { self.schedule.check_end_date = true }, if: 'schedule' # data final obrigatoria

  validates :title, :description, :schedule, presence: true
  validates :title, length: { maximum: 255 }

  def period
    p = [I18n.l(start_date, format: :normal)]
    p << I18n.l(end_date, format: :normal) if end_date && end_date != start_date
    p.join(' - ')
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
    Notification.find_by_sql <<-SQL
      WITH ats AS (
        SELECT DISTINCT at.id
        FROM related_taggables rt
        JOIN allocation_tags at ON at.id = rt.group_at_id OR at.id = rt.offer_at_id OR at.id = rt.course_at_id OR at.id = rt.curriculum_unit_at_id OR at.id = rt.curriculum_unit_type_at_id
        JOIN allocations al ON al.allocation_tag_id = group_at_id OR al.allocation_tag_id = offer_at_id OR al.allocation_tag_id = course_at_id OR al.allocation_tag_id = curriculum_unit_at_id OR al.allocation_tag_id = curriculum_unit_type_at_id
        WHERE al.user_id = #{user.id}
        AND al.status = #{Allocation_Activated}
      )
      SELECT DISTINCT notifications.id, notifications.*, rn.user_id AS read
      FROM notifications
      JOIN schedules ON schedules.id = notifications.schedule_id
      JOIN academic_allocations ac ON ac.academic_tool_id = notifications.id AND ac.academic_tool_type = 'Notification'
      LEFT JOIN read_notifications rn ON rn.notification_id = notifications.id AND rn.user_id = #{user.id}
      WHERE ac.allocation_tag_id IN (select id FROM ats) OR ac.allocation_tag_id IS NULL
      AND schedules.start_date::date <= current_date AND schedules.end_date::date >= current_date
    SQL
  end

  def self.general_warnings
    Notification.find_by_sql <<-SQL
      SELECT DISTINCT notifications.id, notifications.*
      FROM notifications
      JOIN schedules ON schedules.id = notifications.schedule_id
      JOIN academic_allocations ac ON ac.academic_tool_id = notifications.id AND ac.academic_tool_type = 'Notification'
      WHERE ac.allocation_tag_id IS NULL
    SQL
  end

end
