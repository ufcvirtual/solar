class Lesson < ActiveRecord::Base

  belongs_to :allocation_tag
  belongs_to :user
  belongs_to :schedule

  def self.to_open(allocation_tag_id = nil, lesson_id = nil)

    all_allocations = AllocationTag.find_related_ids(allocation_tag_id)

    # uma aula é ligada a uma turma ou a uma oferta
    query_lessons = "SELECT DISTINCT l.id AS lesson_id,
                            l.name,
                            l.address,
                            l.order,
                            l.type_lesson,
                            l.allocation_tag_id,
                            l.schedule_id
                       FROM lessons         AS l
                  LEFT JOIN schedules       AS s  ON l.schedule_id = s.id
                  LEFT JOIN allocation_tags AS at ON l.allocation_tag_id = at.id
                      WHERE status = #{Lesson_Approved}
                        AND s.start_date <= current_date
                        AND at.id IN (#{all_allocations.join(', ')})"

    # se passou lesson
    query_lessons << " AND l.id = #{lesson_id} " unless lesson_id.nil?
    query_lessons << " ORDER BY l.order"

    return Lesson.find_by_sql(query_lessons)
  end

end
