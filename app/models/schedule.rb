class Schedule < ActiveRecord::Base
  has_many :discussions
  has_many :lessons
  has_many :schedule_events
  has_many :portfolio


  def self.all_by_group_id_and_user_id(group_id, user_id,curriculum_unit_id )
    ActiveRecord::Base.connection.select_all  <<SQL
    SELECT * FROM (
      (    SELECT t1.name, t1.description, t4.start_date,t4.end_date , 'discussions' AS schedule_type
      FROM discussions AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND t2.group_id = #{group_id}
      AND t2.curriculum_unit_id = #{curriculum_unit_id}
      )
      union
      (    SELECT t1.name, t1.description, t4.start_date,t4.end_date, 'lessons' AS schedule_type
      FROM lessons AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND t2.group_id = #{group_id}
      AND t2.curriculum_unit_id = #{curriculum_unit_id}
      )
      union
      (
      SELECT t1.name,t1.enunciation AS description, t1.start_date,t1.end_date, 'assignments' AS schedule_type
      FROM assignments AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND t2.group_id = #{group_id}
      AND t2.curriculum_unit_id = #{curriculum_unit_id}
      )
      union
      (
      SELECT t1.title AS name,t1.description,t4.start_date,t4.end_date, 'schedule_events' AS schedule_type
      FROM schedule_events AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND t2.group_id = #{group_id}
      AND t2.curriculum_unit_id = #{curriculum_unit_id}
      )
) AS final

ORDER BY final.end_date 

SQL
  end

end
