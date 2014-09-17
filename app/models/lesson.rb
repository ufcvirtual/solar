class Lesson < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  has_many :academic_allocations, through: :lesson_module

  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule

  has_many :allocation_tags, through: :lesson_module
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  before_create :set_order
  before_save :url_protocol, :if => :is_link?
  after_save :create_or_update_folder

  before_destroy :can_destroy?
  after_destroy :delete_schedule, :delete_files

  validates :lesson_module, :schedule, presence: true
  validates :name, :type_lesson, presence: true
  validates :address, presence: true, if: "not(is_draft?) and persisted?"

  validate :initial_file_setted?

  # Na expressão regular os protocolos http, https e ftp podem aparecer somente uma vez ou não aparecer.
  validates_format_of :address, :with => /\A((http|https|ftp):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z/ix,
  :allow_nil => true, :allow_blank => true, :if => :is_link?

  attr_accessible :name, :description, :type_lesson, :address, :schedule_attributes, :lesson_module_id, :schedule_id

  accepts_nested_attributes_for :schedule

  FILES_PATH = Rails.root.join('media', 'lessons') # path dos arquivos de aula

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

  def path(full_path = false, with_address = true)
    if is_file?
      FileUtils.mkdir_p(FILES_PATH.join(id.to_s)) # verifica se diretório existe ou não; se não, cria.

      p_address = with_address ? address : ''
      full_path ? FILES_PATH.join(id.to_s, p_address) : File.join('', 'media', 'lessons', id.to_s, p_address)
    else
      # se for vídeo do youtube que não esteja como embeded, altera link
      (address.include?("youtube") and not(address.include?("embed"))) ? 'http://www.youtube.com/embed/' + address.split("v=")[1] : address
    end
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

  private

    def can_destroy?
      unless is_draft? # aula em rascunho
        draft!
        errors.add(:base, I18n.t('lessons.errors.cant_delete'))
        return false
      end
      true
    end

    def initial_file_setted?
      errors.add(:base, I18n.t("lessons.errors.url_must_be_informed")) if is_link? and address.blank? and not(is_draft?)

      unless is_draft? or is_link? # se for rascunho ou link pode nao ter um arquivo inicial
        errors.add(:base, I18n.t('lesson_files.define_initial_file_error')) unless is_file? and address.present? and File.exist?(path(true).to_s)
      end
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
