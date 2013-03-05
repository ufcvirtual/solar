class Lesson < ActiveRecord::Base
  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule

  has_one :allocation_tag, through: :lesson_module

  before_destroy :can_destroy?
  after_destroy  :delete_schedule

  validates :name, presence: true

  FILES_PATH_URL = Pathname.new(File.join('media', 'lessons'))
  FILES_PATH = Rails.root.join(FILES_PATH_URL.to_s) # path dos arquivos de aula

  def path(full = false)
    if type_lesson.to_i == Lesson_Type_File
      return unless File.exist? FILES_PATH.join(id.to_s)
      full ? FILES_PATH.join(id.to_s, address) : File.join('', 'media', 'lessons', id.to_s, address)
    else
      address
    end
  end

  def can_destroy?
    return (status == 0 ? true : false) # verifica se se a aula está em teste ou aprovada
  end

  def delete_schedule
    self.schedule.destroy
  end

  def has_end_date?
    (try(:schedule).try(:end_date) != try(:schedule).try(:start_date))
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

end
