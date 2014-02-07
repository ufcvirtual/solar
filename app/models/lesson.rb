class Lesson < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION = true, true

  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule

  has_many :allocation_tags, through: :lesson_module

  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  before_save :url_protocol, :if => :is_link?
  after_save :create_or_update_folder

  before_destroy :can_destroy?
  after_destroy :delete_schedule, :delete_files

  validates :name, :type_lesson, presence: true
  validates :address, presence: true, :if => :is_link?
  validate  :initial_file_setted
  validates :lesson_module, presence: true

  # Na expressão regular os protocolos http, https e ftp podem aparecer somente uma vez ou não aparecer.
  validates_format_of :address, :with => /^((http|https|ftp):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
  :allow_nil => true, :allow_blank => true, :if => :is_link?
  
  FILES_PATH = Rails.root.join('media', 'lessons') # path dos arquivos de aula

  def initial_file_setted
    unless is_draft? or is_link?
      errors.add(:base, I18n.t(:define_initial_file_error, scope: [:lesson_files])) unless is_file? and address.present? and File.exist?(path(true).to_s)
    end
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

  def url_protocol
    self.address = 'http://' + self.address if (self.address =~ URI::regexp(["ftp", "http", "https"])).nil? 
  end 

  def path(full = false, with_address = true)
    if type_lesson == Lesson_Type_File
      Dir.mkdir(FILES_PATH.join(id.to_s)) unless File.exist? FILES_PATH.join(id.to_s) # verifica se diretório existe ou não; se não, cria.
      full ? FILES_PATH.join(id.to_s, (with_address ? address : '')) : File.join('', 'media', 'lessons', id.to_s, (with_address ? address : ''))
    else
      #se for vídeo do youtube que não esteja como embeded, altera link
      return (address.include?("youtube") and !address.include?("embed"))  ? 'http://www.youtube.com/embed/'+address.split("v=")[1] : address 
    end
  end

  def can_destroy?
    unless is_draft? # aula em rascunho
      errors.add(:lesson, I18n.t(:cant_delete, :scope => [:lesson, :errors]))
      return false
    end
  end

  def delete_schedule
    self.schedule.destroy
  end

  def has_end_date?
    !!(try(:schedule).try(:end_date))
  end

  # pode visualizar
  def open_to_show?
    started? and not closed?
  end

  # já iniciou
  def started?
    schedule.start_date <= Date.today
  end

  # fechado
  def closed?
    not(schedule.end_date.nil?) and (schedule.end_date < Date.today)
  end  

  def self.to_open(allocation_tag_ids)
    select(["lessons.id", "lessons.name", :address, "lessons.order", :type_lesson, :schedule_id])
    .joins([{lesson_module: :academic_allocations}, schedule: {}])
    .where({
      status: Lesson_Approved, 
      academic_allocations: { allocation_tag_id: allocation_tag_ids}
    })
    .where("schedules.start_date <= current_date")
    .order("lessons.order")
    .uniq
  end

  private

    def delete_files
      if (type_lesson == Lesson_Type_File) and (status == Lesson_Test)
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
