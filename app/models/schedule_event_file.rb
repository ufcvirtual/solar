class ScheduleEventFile < ActiveRecord::Base

  include AcademicTool
  include FilesHelper
  include SentActivity

  FILESIZE = 26.megabyte

  belongs_to :user
  belongs_to :academic_allocation_user, counter_cache: true

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false

  before_destroy :can_destroy?
  before_save :replace_attachment_file_name

  validates :attachment, presence: true
  validates :academic_allocation_user_id, presence: true

  serialize :file_correction, JSON

  has_attached_file :attachment,
    path: ":rails_root/media/schedule_event/schedule_event_files/:id_:basename.:extension",
    url: "/media/schedule_event/schedule_event_files/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: FILESIZE, message: I18n.t('schedule_event_files.error.attachment_file_size_too_big')
  validates_attachment_content_type :attachment, content_type: /(^image\/(jpeg|jpg|gif|png)$)|\Aapplication\/pdf/, message: I18n.t('schedule_event_files.error.wrong_type')

  Paperclip.interpolates :normalized_attachment_file_name do |attachment, style|
    attachment.instance.normalized_attachment_file_name
  end

  def normalized_attachment_file_name
    file_name = self.attachment_file_name.gsub( /[^a-zA-Z0-9\.]/, '_').split("#{self.academic_allocation_user.user.cpf}_").join("")
    "#{self.academic_allocation_user.user.cpf}_#{file_name}"
  end

  def can_destroy?
    raise 'remove' if !academic_allocation_user.grade.nil? || (academic_allocation.frequency_automatic == true && academic_allocation_user.evaluated_by_responsible == true) || (academic_allocation.frequency_automatic == false && !academic_allocation_user.working_hours.nil?) || academic_allocation_user.comments_count > 0
  end

  def delete_with_dependents
    self.delete
  end

  def self.get_all_event_files event_id
    ScheduleEventFile.joins("INNER JOIN academic_allocation_users AS acu ON schedule_event_files.academic_allocation_user_id = acu.id
                            INNER JOIN academic_allocations AS ac ON acu.academic_allocation_id = ac.id")
                      .where("ac.academic_tool_id = ? AND ac.academic_tool_type = 'ScheduleEvent'", event_id)
  end

  private

    def replace_attachment_file_name
      self.attachment_file_name = normalized_attachment_file_name
    end
end
