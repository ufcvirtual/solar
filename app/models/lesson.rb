class Lesson < ActiveRecord::Base
  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule

  has_one :allocation_tag, through: :lesson_module

  after_create :create_or_update_folder
  after_update :create_or_update_folder

  before_destroy :can_destroy?
  after_destroy :delete_schedule, :delete_files

  validates :name, :type_lesson, presence: true #:address
  validate :initial_file_setted

  validates_format_of :address, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix, :message => I18n.t("lessons.errors.invalid_link"), :if => :is_link?
  
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

  def self.to_open(allocation_tags_ids = nil, lesson_id = nil)
    # uma aula é ligada a um modulo que eh ligado a uma turma ou a uma oferta
    query_lessons = <<SQL
       SELECT DISTINCT l.id AS lesson_id,
              l.name,
              l.address,
              l.order,
              l.type_lesson,
              m.allocation_tag_id,
              l.schedule_id,
              CASE WHEN s.end_date < current_date THEN true ELSE false END AS closed
         FROM lessons         AS l
    LEFT JOIN schedules       AS s  ON l.schedule_id = s.id
    INNER JOIN lesson_modules AS m  ON l.lesson_module_id = m.id
    LEFT JOIN allocation_tags AS at ON m.allocation_tag_id = at.id
        WHERE status = #{Lesson_Approved}
          AND s.start_date <= current_date
          AND at.id IN (#{allocation_tags_ids})
SQL

    # id da aula foi passado
    query_lessons << " AND l.id = #{lesson_id} " unless lesson_id.nil?
    query_lessons << " ORDER BY l.order"

    Lesson.find_by_sql(query_lessons)
  end

  private

    def delete_files
      if (type_lesson == Lesson_Type_File) and (status == Lesson_Test)
        file = path(full = true, address = false).to_s
        FileUtils.remove_dir(file) if File.exist?(file)
      end
    end

    def create_or_update_folder
      if type_lesson == Lesson_Type_Link and File.exist?(path(true))
        FileUtils.remove_dir(path(true)) 
      else
        FileUtils.mkdir_p(FILES_PATH.join(id.to_s))
      end
    end

end
