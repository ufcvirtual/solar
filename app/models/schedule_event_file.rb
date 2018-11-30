class ScheduleEventFile < ActiveRecord::Base

  include AcademicTool
  include FilesHelper
  include SentActivity

  FILESIZE = 6.megabyte

  belongs_to :user
  belongs_to :academic_allocation_user, counter_cache: true

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  has_one :allocation_tag, through: :academic_allocation_user
  has_one :schedule_event, through: :academic_allocation_user

  before_destroy :can_destroy?
  before_save :replace_attachment_file_name

  validates :attachment, presence: true
  validates :academic_allocation_user_id, presence: true
  validate :verify_type

  validate :verify_dates

  serialize :file_correction, JSON

  has_attached_file :attachment,
    path: ":rails_root/media/schedule_event/schedule_event_files/:id_:basename.:extension",
    url: "/media/schedule_event/schedule_event_files/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: FILESIZE, message: I18n.t('schedule_event_files.error.attachment_file_size_too_big', file: FILESIZE/1000/1000)
  validates_attachment_content_type :attachment, content_type: /(^image\/(jpeg|jpg|gif|png)$)|\Aapplication\/pdf/, message: I18n.t('schedule_event_files.error.wrong_type')

  attr_accessor :merge

  Paperclip.interpolates :normalized_attachment_file_name do |attachment, style|
    attachment.instance.normalized_attachment_file_name
  end

  def normalized_attachment_file_name
    # if merge
    #   self.attachment_file_name
    # else
    #   "#{self.academic_allocation_user.user.name.split(' ').join('_')}-#{self.attachment_file_name}".gsub( /[^a-zA-Z0-9_\.\-]/, '')
    # end
    
    if self.id.nil?
      "#{self.academic_allocation_user.user.name.split(' ').join('_')}-#{self.attachment_file_name}".gsub( /[^a-zA-Z0-9_\.\-]/, '')
    else
      self.attachment_file_name
    end
  end

  def verify_type
    event = ScheduleEvent.find(AcademicAllocationUser.find(academic_allocation_user_id).academic_allocation.academic_tool_id)
    errors.add(:base, 'schedule_event_files.error.type') unless [Presential_Meeting, Presential_Test].include?(event.type_event)
  end

  def can_destroy?
    raise 'remove' if !academic_allocation_user.grade.blank? || (academic_allocation.frequency_automatic == true && academic_allocation_user.evaluated_by_responsible == true) || (academic_allocation.frequency_automatic == false && !academic_allocation_user.working_hours.blank?) || academic_allocation_user.comments_count > 0
    raise 'offer' unless allocation_tag.verify_offer_period
  end

  def delete_with_dependents
    self.delete
  end

  def self.get_all_event_files event_id
    ScheduleEventFile.joins("INNER JOIN academic_allocation_users AS acu ON schedule_event_files.academic_allocation_user_id = acu.id
                            INNER JOIN academic_allocations AS ac ON acu.academic_allocation_id = ac.id")
                      .where("ac.academic_tool_id = ? AND ac.academic_tool_type = 'ScheduleEvent'", event_id)
  end

  def can_send?
    schedule_event.ended? && allocation_tag.verify_offer_period
  end

  def verify_dates
    errors.add(:base, I18n.t('schedule_event_files.error.ended')) unless schedule_event.ended?
    errors.add(:base, I18n.t('schedule_event_files.error.offer')) unless allocation_tag.verify_offer_period
  end

  private

    def replace_attachment_file_name
      self.attachment_file_name = normalized_attachment_file_name
    end
end
