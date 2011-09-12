class Schedule < ActiveRecord::Base
  has_many :discussions
  has_many :lessons
  has_many :schedule_events
  has_many :portfolio

  def self.all_by_curriculum_unit_id_and_offer_id_group_id_and_user_id(curriculum_unit_id, offer_id, group_id, user_id, period = false, date_search = nil)

    date_search_option = ''
    date_search_option = "AND (t2.start_date = current_date OR t2.end_date = current_date)" if date_search.nil? && period
    date_search_option = "AND (t2.start_date = '#{date_search}' OR t2.end_date = '#{date_search}')" unless date_search.nil?

    ActiveRecord::Base.connection.select_all <<SQL
    WITH cte_allocations AS (
       SELECT t1.id           AS allocation_tag_id,
              t1.curriculum_unit_id,
              t1.offer_id,
              t1.group_id
         FROM allocation_tags AS t1
         JOIN allocations     AS t2 ON t2.allocation_tag_id = t1.id
        WHERE t2.user_id = #{user_id}
          AND t2.status = #{Allocation_Activated}
    ),
    -- descobrir todas as ofertas desses curriculum_units dessas allocations
    cte_offers_by_curriculum_unit AS (
        SELECT t1.allocation_tag_id,
               t1.curriculum_unit_id,
               t2.id           AS offer_id
          FROM cte_allocations AS t1
          JOIN offers          AS t2 ON t2.curriculum_unit_id = t1.curriculum_unit_id
    ),
    -- descobrir todos os grupos dessas ofertas
    cte_groups_by_offers_by_uc AS (
        SELECT t1.allocation_tag_id,
               t1.curriculum_unit_id,
               t1.offer_id,
               t2.id AS group_id
          FROM cte_offers_by_curriculum_unit AS t1
          JOIN groups                        AS t2 ON t2.offer_id = t1.offer_id
    ),
    -- todas as allocation_tags da unidade curricular
    cte_allocations_by_uc AS (
        SELECT t1.id           AS allocation_tag_id,
               t1.curriculum_unit_id,
               t1.offer_id,
               t1.group_id
          FROM allocation_tags AS t1
         WHERE t1.group_id           IN (SELECT group_id FROM cte_groups_by_offers_by_uc)
            OR t1.offer_id           IN (SELECT offer_id FROM cte_offers_by_curriculum_unit)
            OR t1.curriculum_unit_id IN (SELECT curriculum_unit_id FROM cte_allocations)
    ),
    -- descobrir todos os grupos dessas ofertas
    cte_groups_by_offers AS (
        SELECT t1.allocation_tag_id,
               t1.curriculum_unit_id,
               t1.offer_id,
               t2.id           AS group_id
          FROM cte_allocations AS t1
          JOIN groups          AS t2 ON t2.offer_id = t1.offer_id
    ),
    -- allocations by offers
    cte_allocations_by_offers AS (
        SELECT t1.id           AS allocation_tag_id,
               t1.curriculum_unit_id,
               t1.offer_id,
               t1.group_id
          FROM allocation_tags AS t1
         WHERE t1.group_id IN (SELECT group_id FROM cte_groups_by_offers)
            OR t1.offer_id IS NOT NULL
     ),
     cte_all_allocation_tags AS  (
        SELECT * FROM cte_allocations_by_uc
        UNION
        SELECT * FROM cte_allocations_by_offers
        UNION
        SELECT * FROM cte_allocations WHERE group_id IS NOT NULL
    )
-- consulta
   SELECT * FROM (
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date , 'discussions' AS schedule_type
          FROM discussions             AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
         WHERE (t3.group_id = #{group_id} OR t3.offer_id = #{offer_id} OR t3.curriculum_unit_id = #{curriculum_unit_id})
               #{date_search_option}
      )
      UNION
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date, 'lessons' AS schedule_type
          FROM lessons                 AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
         WHERE (t3.group_id = #{group_id} OR t3.offer_id = #{offer_id} OR t3.curriculum_unit_id = #{curriculum_unit_id})
               #{date_search_option}
      )
      UNION
      (
      SELECT t1.name, t1.enunciation AS description, t2.start_date, t2.end_date, 'assignments' AS schedule_type
        FROM assignments             AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
       WHERE (t3.group_id = #{group_id} OR t3.offer_id = #{offer_id} OR t3.curriculum_unit_id = #{curriculum_unit_id})
             #{date_search_option}
      )
      UNION
      (
      SELECT t1.title AS name, t1.description, t2.start_date, t2.end_date, 'schedule_events' AS schedule_type
        FROM schedule_events         AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
       WHERE (t3.group_id = #{group_id} OR t3.offer_id = #{offer_id} OR t3.curriculum_unit_id = #{curriculum_unit_id})
             #{date_search_option}
      )
    ) AS t1
   ORDER BY t1.end_date

SQL

  end

end
