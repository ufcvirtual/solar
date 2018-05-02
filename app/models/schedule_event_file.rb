class ScheduleEventFile < ActiveRecord::Base

  # include ControlledDependency
  # include SentActivity
  include AcademicTool
  include FilesHelper

  belongs_to :user
  belongs_to :academic_allocation_user

  # has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  # has_one :schedule_event, through: :academic_allocation_user
  # has_one :allocation_tag, through: :academic_allocation

  # before_save :can_change?, if: 'merge.nil?'
  # before_destroy :can_destroy?

  validates :attachment, presence: true
  validates :academic_allocation_user_id, presence: true

  has_attached_file :attachment,
    path: ":rails_root/media/schedule_event/schedule_event_files/:id_:basename.:extension",
    url: "/media/schedule_event/schedule_event_files/:id_:basename.:extension"

  # validates_attachment_size :attachment_file, less_than: 26.megabyte, message: ' '
  # validates_attachment_content_type_in_black_list :attachment

  def can_change?
    raise 'date_range_expired' unless schedule_event.in_time?
  end

  def can_destroy?
    raise CanCan::AccessDenied unless user_id == User.current.try(:id)
    raise 'date_range_expired' unless schedule_event.in_time?
  end

  def delete_with_dependents
    self.delete
  end
end
