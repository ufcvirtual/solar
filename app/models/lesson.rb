class Lesson < ActiveRecord::Base
  belongs_to :lesson_module
  belongs_to :user
  belongs_to :schedule

  has_one :allocation_tag, :through => :lesson_module

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
