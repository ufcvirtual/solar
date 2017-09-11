class NotificationFile < ActiveRecord::Base

  default_scope order: 'file_updated_at DESC'

  belongs_to :notification

  validates :file, presence: true
  has_attached_file :file,
    path: ":rails_root/media/notifications/:id_:basename.:extension",
    url: "/media/notifications/:id_:basename.:extension"

  validates_attachment_size :file, less_than: 10.megabyte
  validates_attachment_content_type_in_black_list :file

  after_destroy :remove_readings
  after_create :remove_readings

  before_save :verify_end_date
  before_destroy :verify_end_date

  def remove_readings
    ReadNotification.where(notification_id: notification_id).delete_all if notification.started? && !notification.ended?
  end

  def verify_end_date
    if notification.ended?
      errors.add(:file_file_name, I18n.t('notifications.error.ended_file')) 
      raise 'ended'
    end
  end

end
