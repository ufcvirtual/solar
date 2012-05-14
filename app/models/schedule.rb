class Schedule < ActiveRecord::Base

  has_many :discussions
  has_many :lessons
  has_many :schedule_events
  has_many :portfolios
  has_many :assignments
  
  def self.all_by_allocation_tags(allocation_tags, period = false, date_search = nil)

    allocation_tags = allocation_tags.join(',') if allocation_tags.is_a?(Array)

    date_search_option, limit = '', ''
    limit = 'LIMIT 2' if period

    date_search_option = "AND (t2.start_date = current_date OR t2.end_date = current_date)" if date_search.nil? and period
    date_search_option = "AND (t2.start_date = '#{date_search}' OR t2.end_date = '#{date_search}')" unless date_search.nil?

    allocations_where = allocation_tags.nil? ? '' : "WHERE id IN (#{allocation_tags})"

    query = <<SQL
    WITH cte_all_allocation_tags AS (
      SELECT id AS allocation_tag_id, * FROM allocation_tags #{allocations_where}
     )
    -- consulta
   SELECT * FROM (
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date , 'discussions' AS schedule_type, t1.allocation_tag_id
          ,t4.code, t5.semester, t6.name as curriculum_name

          FROM discussions             AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id

          join groups as t4 on t3.group_id = t4.id
          join offers as t5 on t3.offer_id = t5.id or t4.offer_id = t5.id
          join curriculum_units as t6 on t3.curriculum_unit_id = t6.id or t5.curriculum_unit_id = t6.id

           #{date_search_option}
      )
      UNION
      (

        SELECT t1.name, t1.description, t2.start_date, t2.end_date, 'lessons' AS schedule_type, t3.allocation_tag_id
                  ,t5.code, t6.semester, t7.name as curriculum_name

                  FROM lessons                 AS t1
                  JOIN schedules               AS t2 ON t2.id = t1.schedule_id

        join lesson_modules as t3 on t1.lesson_module_id = t3.id
        JOIN cte_all_allocation_tags AS t4 ON t4.allocation_tag_id = t3.allocation_tag_id
        join groups as t5 on t4.group_id = t5.id
        join offers as t6 on t4.offer_id = t6.id or t5.offer_id = t6.id
        join curriculum_units as t7 on t4.curriculum_unit_id = t7.id or t6.curriculum_unit_id = t7.id

           #{date_search_option}
      )
      UNION
      (
      SELECT t1.name, t1.enunciation AS description, t2.start_date, t2.end_date, 'assignment' AS schedule_type, t1.allocation_tag_id
        ,t4.code, t5.semester, t6.name as curriculum_name

        FROM assignments             AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id

        join groups as t4 on t3.group_id = t4.id
        join offers as t5 on t3.offer_id = t5.id or t4.offer_id = t5.id
        join curriculum_units as t6 on t3.curriculum_unit_id = t6.id or t5.curriculum_unit_id = t6.id

           #{date_search_option}
      )
      UNION
      (
      SELECT t1.title AS name, t1.description, t2.start_date, t2.end_date, 'schedule_events' AS schedule_type, t1.allocation_tag_id
        ,t4.code, t5.semester, t6.name as curriculum_name

        FROM schedule_events         AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id

        join groups as t4 on t3.group_id = t4.id
        join offers as t5 on t3.offer_id = t5.id or t4.offer_id = t5.id
        join curriculum_units as t6 on t3.curriculum_unit_id = t6.id or t5.curriculum_unit_id = t6.id

           #{date_search_option}
      )
    ) AS t1
   ORDER BY t1.end_date
   #{limit}
SQL

    ActiveRecord::Base.connection.select_all query
  end

end
