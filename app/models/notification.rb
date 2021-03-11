class Notification < ActiveRecord::Base
  include AcademicTool
  include FilesHelper

  GROUP_PERMISSION = OFFER_PERMISSION = CURRICULUM_UNIT_PERMISSION = COURSE_PERMISSION = CURRICULUM_UNIT_TYPE_PERMISSION = true

  scope :active, -> { joins(:schedule).where("date(schedules.start_date) <= :today and date(schedules.end_date) >= :today", today: Date.today) }

  belongs_to :schedule

  validate :verify_end_date, on: :update, if: 'ended?'

  has_and_belongs_to_many :users, join_table: 'read_notifications'
  has_and_belongs_to_many :profiles, join_table: 'notification_profiles'
  has_many :read_notifications, dependent: :delete_all
  has_many :notification_files, dependent: :destroy
  has_many :notification_profiles, dependent: :destroy

  accepts_nested_attributes_for :schedule
  accepts_nested_attributes_for :notification_files, allow_destroy: true, reject_if: :reject_files

  validates :title, :description, :schedule, presence: true
  validates :title, length: { maximum: 255 }

  after_save :remove_readings, on: :update, if: 'saved_change_to_title? || saved_change_to_description? || (saved_change_to_mandatory_reading? && mandatory_reading)'

  def reject_files(file)
    (file[:file].blank? && (new_record? || file[:id].blank?))
  end

  def remove_readings
    read_notifications.where(notification_id: id).delete_all if started? && !ended?
  end

  def copy_dependencies_from(notification_to_copy)
    unless notification_to_copy.notification_files.empty?
      notification_to_copy.notification_files.each do |file|
        new_file = NotificationFile.create! file.attributes.merge({ notification_id: self.id })
        copy_file(file, new_file, 'notifications', 'file')
      end
    end
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
        AND rt.group_status = 't'
        AND al.status = #{Allocation_Activated}
      )
      SELECT DISTINCT notifications.id, notifications.*, rn.user_id AS read
      FROM notifications
      JOIN schedules ON schedules.id = notifications.schedule_id
      JOIN academic_allocations ac ON ac.academic_tool_id = notifications.id AND ac.academic_tool_type = 'Notification'
      LEFT JOIN read_notifications rn ON rn.notification_id = notifications.id AND rn.user_id = #{user.id}
      LEFT JOIN notification_profiles np ON np.notification_id = notifications.id
      LEFT JOIN profiles p ON np.profile_id = p.id
      WHERE (
              (
                -- if no profile was defined
                p.id IS NULL AND
                -- verify if user has permission to access notification
                (ac.allocation_tag_id IN (select id FROM ats) OR ac.allocation_tag_id IS NULL)
              ) OR (
                -- if profiles were defined
                p.id IS NOT NULL
                -- verify user allocations and profiles and notification ATs
                AND (
                  -- if notification has no at, get all users with that profile
                  (
                    ac.allocation_tag_id IS NULL AND
                    EXISTS(SELECT al.profile_id AS id
                      FROM allocations al
                      WHERE al.user_id = #{user.id}
                      AND al.status = #{Allocation_Activated}
                      AND al.profile_id = p.id)
                  ) OR (
                    -- or if notification has at
                    ac.allocation_tag_id IS NOT NULL AND
                    -- gets all user with that profile and related at or general allocation
                    EXISTS(SELECT at.id, al.profile_id
                      FROM allocations al
                      LEFT JOIN related_taggables rt ON al.allocation_tag_id = group_at_id OR al.allocation_tag_id = offer_at_id OR al.allocation_tag_id = course_at_id OR al.allocation_tag_id = curriculum_unit_at_id OR al.allocation_tag_id = curriculum_unit_type_at_id
                      LEFT JOIN allocation_tags at ON at.id = rt.group_at_id OR at.id = rt.offer_at_id OR at.id = rt.course_at_id OR at.id = rt.curriculum_unit_at_id OR at.id = rt.curriculum_unit_type_at_id
                      WHERE al.user_id = #{user.id}
                      AND al.status = #{Allocation_Activated}
                      AND (at.id = ac.allocation_tag_id OR at.id IS NULL)
                      AND (rt.group_status = 't' OR rt.id IS NULL)
                      AND al.profile_id = p.id)
                  )
                )
              )
            ) #{query}
      AND schedules.start_date::date <= current_date AND schedules.end_date::date >= current_date
      ORDER BY notifications.updated_at DESC;
    SQL
  end

  def self.mandatory_of_user(user)
    Notification.of_user(user, true)
  end

  def self.general_warnings
    Notification.joins(:academic_allocations).where(academic_allocations: {allocation_tag_id: nil})
  end

end
