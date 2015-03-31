class Lesson < Event

  GROUP_PERMISSION = OFFER_PERMISSION = true

  has_many :academic_allocations, through: :lesson_module

  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule

  has_many :allocation_tags, through: :lesson_module
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags
  has_many :notes, class_name: 'LessonNote', foreign_key: 'lesson_note_id', dependent: :destroy

  before_create :set_order
  before_save :url_protocol, if: :is_link?
  after_save :create_or_update_folder

  before_destroy :can_destroy?
  after_destroy :delete_schedule, :delete_files

  validates :lesson_module, :schedule, presence: true
  validates :name, :type_lesson, presence: true
  validates :address, presence: true, if: "not(is_draft?) and persisted?"

  validate :address_is_ok?

  # Na expressão regular os protocolos http, https e ftp podem aparecer somente uma vez ou não aparecer.
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
    (is_file? and address.present? and File.exist?(path(true)))
  end

  def valid_link?
    (is_link? and not(address.blank?))
  end

  def delete_schedule
    self.schedule.destroy rescue nil
  end

  def has_end_date?
    !!(try(:schedule).try(:end_date))
  end

  # pode visualizar
  def open_to_show?
    started? and not(closed?)
  end

  # já iniciou
  def started?
    schedule.start_date.to_date <= Date.today
  end

  # fechado
  def closed?
    not(schedule.end_date.nil?) and (schedule.end_date.to_date < Date.today)
  end

  # ainda não iniciou
  def will_open?
    not(started?) and not(closed?)
  end

  def path(full_path = false, with_address = true)
    return link_path if is_link?
    file_path(full_path, with_address)
  end

  def file_path(full_path = false, with_address = true)
    raise 'not file' unless is_file?

    p_address = with_address ? address : ''

    return FILES_PATH.join(id.to_s, p_address) if full_path
    File.join('', 'media', 'lessons', id.to_s, p_address)
  end

  def link_path(api: false)
    raise 'not link' unless is_link?

    return 'http://www.youtube.com/embed/' + address.split("v=")[1] if not(api) and address.include?("youtube") and not address.include?("embed")
    address
  end

  def offer
    offers.first || groups.first.offer
  end

  def self.limited(user, ats)
    query = []
    query << 'lessons.status = 1' if user.profiles_with_access_on('see_drafts', 'lessons', ats, true).empty?
    # recuperar as aulas que o usuário pode acessar usuário
    Lesson.joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: ats }).where(query.join(" AND "))
  end

  def self.all_by_ats(ats, query = {})
    joins(lesson_module: :academic_allocations).where(academic_allocations: { allocation_tag_id: ats }).where(query)
  end

  private

    def can_destroy?
      unless is_draft? # aula em rascunho
        draft!
        errors.add(:base, I18n.t('lessons.errors.cant_delete'))
        return false
      end
    end

    def address_is_ok?
      return true if is_draft?

      errors.add(:base, I18n.t("lessons.errors.url_must_be_informed")) if is_link? and not valid_link?
      errors.add(:base, I18n.t('lesson_files.define_initial_file_error')) if is_file? and not valid_file?
    end

    def url_protocol
      self.address = "http://#{address}" if not(address.blank?) and (address =~ URI::regexp(["ftp", "http", "https"])).nil?
    end

    def set_order
      self.order = lesson_module.next_lesson_order if order.nil?
    end

    def delete_files
      if is_file? and is_draft?
        file = path(full = true, address = false).to_s
        FileUtils.remove_dir(file) if File.exist?(file)
      end
    end

    def create_or_update_folder
      if is_link? and File.exist?(path(true))
        FileUtils.remove_dir(path(true))
      elsif is_file?
        FileUtils.mkdir_p(FILES_PATH.join(id.to_s))
      end
    end

end
