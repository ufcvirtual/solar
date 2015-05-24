require 'fileutils'
class Lesson < Event

  GROUP_PERMISSION = OFFER_PERMISSION = true

  has_many :academic_allocations, through: :lesson_module

  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule
  belongs_to :imported_from, class_name: 'Lesson'

  has_many :allocation_tags, through: :lesson_module
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags
  has_many :notes, class_name: 'LessonNote', foreign_key: 'lesson_id', dependent: :destroy
  has_many :imported_to, class_name: 'Lesson', foreign_key: 'imported_from_id'

  before_create :set_order

  before_save :url_protocol,        if: :is_link?
  before_save :set_receive_updates, if: 'receive_updates_changed?'
  before_save :receive_changes,     if: :must_receive_changes?

  after_save :send_changes,         if: :must_send_changes?
  after_save :create_or_update_folder
  after_save :lesson_privacy,       if: 'privacy_changed?'
  after_save :remove_dir_files,     if: :must_receive_changes?
  
  before_destroy :can_destroy?, :verify_files_before_destroy

  after_destroy :delete_schedule, :delete_files

  validates :lesson_module, :schedule, presence: true
  validates :name, :type_lesson, presence: true
  validates :address, presence: true, if: '!is_draft? && persisted?'

  validate :address_is_ok?
  validate :can_change_privacy?, if: '!new_record? && privacy_changed?'
 
  # Na expressao regular os protocolos http, https e ftp podem aparecer somente uma vez ou nao aparecer
  validates_format_of :address, with: /\A((http|https|ftp):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z/ix,
  allow_nil: true, allow_blank: true, if: :is_link?

  accepts_nested_attributes_for :schedule

  FILES_PATH = Rails.root.join('media', 'lessons') # path dos arquivos de aula

  def type_info
    is_link? ? :LINK : :FILE
  end

  def draft!
    update_attribute('status', Lesson_Test)
  end

  def is_draft?
    status == Lesson_Test
  end

  def is_file?
    type_lesson == Lesson_Type_File
  end

  def is_link?
    type_lesson == Lesson_Type_Link
  end

  def valid_file?
    (is_file? && address.present? && File.exist?(path(true)))
  end

  def valid_link?
    is_link? && !address.blank?
  end

  def delete_schedule
    self.schedule.destroy rescue nil
  end

  def has_end_date?
    !!(try(:schedule).try(:end_date))
  end

  def open_to_show?
    started? && !closed?
  end

  def started?
    schedule.start_date.to_date <= Date.today
  end

  def closed?
    !schedule.end_date.nil? && schedule.end_date.to_date < Date.today
  end

  def will_open?
    !started? && !closed?
  end

  def content_type
    return 'link' if is_link?
    MIME::Types.type_for(path).first.content_type
  end

  def path(full_path = false, with_address = true)
    return link_path if is_link?
    file_path(full_path, with_address)
  end

  def file_path(full_path = false, with_address = true)
    raise 'not file' unless is_file?

    p_address = with_address ? address : ''

    return imported_from.file_path(full_path, with_address) unless imported_from.nil? || has_files?

    return File.join(directory, p_address) if full_path
    File.join('', 'media', 'lessons', id.to_s, p_address)
  end

  def link_path(api: false)
    raise 'not link' unless is_link?

    return 'http://www.youtube.com/embed/' + address.split('v=')[1] if !api && address.include?('youtube') && !address.include?('embed')
    address
  end

  def offer
    offers.first || groups.first.offer
  end

  def self.limited(user, ats)
    query = []
    query << 'lessons.status = 1' if user.profiles_with_access_on('see_drafts', 'lessons', ats, true).empty?
    Lesson.joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: ats }).where(query.join(" AND "))
  end

  def self.all_by_ats(ats, query = {})
    joins(lesson_module: :academic_allocations).where(academic_allocations: { allocation_tag_id: ats }).where(query)
  end

  def copy_files_if_imported
    return true if imported_from_id.nil? || is_link?

    create_or_update_folder unless Dir.exists?(directory)
    FileUtils.copy_entry imported_from.file_path(true, false), directory 
  end

  def verify_files_before_change
    if has_files?
      verify_children_files
    else
      copy_files_if_imported
      verify_children_files
    end
    return true
  rescue
    return false
  end

  def has_files?
    !new_record? && (File.exists?(File.join(directory, address)) || Dir[File.join(directory, '*')].any?)
  end

  def verify_children_files
    (lessons = receive_updates_lessons).each do |lesson|
      lesson.verify_children_files
      FileUtils.rm_rf Dir.glob(File.join(lesson.directory, '*'))
      attributes = { address: address }
      attributes.merge!(status: status) if address.blank?
      lesson.update_attributes attributes
    end

    (imported_to - lessons).each do |lesson|
      lesson.copy_files_if_imported unless lesson.has_files?
    end
  end

  def can_import?(user)
    !privacy || (user_id == user)
  end

  def can_receive_updates?
    new_record? || imported_from.nil? || !imported_from.privacy || (imported_from.privacy && imported_from.user_id != user_id)
  end

  def receive_updates_lessons
    query = { receive_updates: true }
    query.merge!(user_id: user_id) if privacy
    imported_to.where(query)
  end

  def directory
    File.join(Lesson::FILES_PATH, id.to_s)
  end

  private

    def can_destroy?
      unless is_draft?
        draft!
        errors.add(:base, I18n.t('lessons.errors.cant_delete'))
        return false
      end
    end

    def must_send_changes?
      !new_record? && receive_updates_lessons.any? && (name_changed? || description_changed? || address_changed? || type_lesson_changed?)
    end

    def must_receive_changes?
      !new_record? && !imported_from.nil? && receive_updates_changed? && receive_updates && (!imported_from.privacy || imported_from.user_id == user_id)
    end

    def address_is_ok?
      return true if is_draft?

      errors.add(:address, I18n.t('lessons.errors.url_must_be_informed')) if is_link? && !valid_link?
      errors.add(:base, I18n.t('lesson_files.define_initial_file_error')) if is_file? && !valid_file?
    end

    def can_change_privacy?
      errors.add(:privacy, I18n.t('lessons.errors.owner')) if user_id != User.current.id
    end

    def url_protocol
      self.address = "http://#{address}" if !address.blank? && (address =~ URI::regexp(['ftp', 'http', 'https'])).nil?
    end

    def set_order
      if order.nil?
        self.order = lesson_module.next_lesson_order 
      else
        self.order += 1 while lesson_module.lessons.where(order: self.order).any?
      end
    end

    def set_receive_updates
      self.receive_updates = (imported_from_id.nil? ? false : receive_updates)
      nil
    end

    def delete_files
      FileUtils.remove_dir(directory) if is_file? && is_draft? && Dir.exists?(directory)
    end

    def create_or_update_folder
      case 
      when is_link? && Dir.exist?(directory) then FileUtils.remove_dir(directory)
      when is_file? then FileUtils.mkdir_p(directory)
      end
    end

    def send_changes
      ActiveRecord::Base.transaction do
        attributes_to_send = { name: name, description: description, address: address, type_lesson: type_lesson }
        receive_updates_lessons.each do |lesson|
          lesson.update_attributes attributes_to_send.merge!(status: lesson.has_files? ? lesson.status : status) 
        end
      end
    end

    def receive_changes
      self.name        = imported_from.name
      self.description = imported_from.description
      self.address     = imported_from.address
      self.type_lesson = imported_from.type_lesson
      self.status      = imported_from.status
    end

    def lesson_privacy
      return true if new_record?
      if privacy
        imported_to.where(receive_updates: true).where('user_id != ?', user_id).each do |lesson|
          Thread.new do
            Notifier.imported_from_private(lesson).deliver
          end
        end
      end
    end

    def verify_files_before_destroy
      self.imported_to.each do |lesson|
        lesson.copy_files_if_imported unless lesson.has_files?
      end
      self.imported_to.update_all imported_from_id: nil
    end

    def remove_dir_files
      FileUtils.rm_rf Dir.glob(File.join(directory, '*')) if Dir.exists?(directory)
    end

end
