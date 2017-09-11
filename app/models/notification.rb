class Notification < ActiveRecord::Base
  include AcademicTool

  GROUP_PERMISSION = OFFER_PERMISSION = CURRICULUM_UNIT_PERMISSION = COURSE_PERMISSION = CURRICULUM_UNIT_TYPE_PERMISSION = true

  scope :active, -> { joins(:schedule).where("date(schedules.start_date) <= :today and date(schedules.end_date) >= :today", today: Date.today) }

  belongs_to :schedule

  has_and_belongs_to_many :users, join_table: 'read_notifications'
  has_many :read_notifications, dependent: :destroy
  has_many :notification_files, dependent: :destroy

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :notification_files, allow_destroy: true, reject_if: :reject_files

  validates :title, :description, :schedule, presence: true
  validates :title, length: { maximum: 255 }

  validate :verify_end_date, on: :update, if: 'ended?'

  after_save :remove_readings, on: :update, if: 'title_changed? || description_changed? || (mandatory_reading_changed? && mandatory_reading)'

  def reject_files(file)
    (file[:file].blank? && (new_record? || file[:id].blank?))
  end

  def remove_readings
    read_notifications.where(notification_id: id).delete_all if started? && !ended?
  end

  def verify_end_date
    errors.add(:title, I18n.t('notifications.error.ended')) if title_changed?
    errors.add(:description, I18n.t('notifications.error.ended')) if description_changed?
    errors.add(:mandatory_reading, I18n.t('notifications.error.ended')) if mandatory_reading_changed?
  end

  def period
    p = [I18n.l(start_date, format: :normal)]
    p << I18n.l(end_date, format: :normal) if end_date && end_date != start_date
    p.join(' - ')
  end

  def start_date
    schedule.start_date
  end

  def started?
    (Date.today >= schedule.start_date)
  end

  def ended?
    (Date.today > schedule.end_date)
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

  def mark_as_unread(user)
    read_notifications.where(user_id: user).delete_all if read?(user)
  end

  def self.of_user(user, mandatory = false)
    query = (mandatory ? " AND mandatory_reading = 't' AND rn.notification_id IS NULL" : '')

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
      WHERE (ac.allocation_tag_id IN (select id FROM ats) OR ac.allocation_tag_id IS NULL) #{query}
      AND schedules.start_date::date <= current_date AND schedules.end_date::date >= current_date
      ORDER BY notifications.id;
    SQL
  end

  def self.mandatory_of_user(user)
    Notification.of_user(user, true)
  end

  def self.general_warnings
    Notification.joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: nil})
  end

end
