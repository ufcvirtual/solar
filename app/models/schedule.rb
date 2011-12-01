class Schedule < ActiveRecord::Base

  has_many :discussions
  has_many :lessons
  has_many :schedule_events
  has_many :portfolio
  has_many :assignment

  ##
  # DEPRECATED - utilizar all_by_allocations
  #
  #
  # Todas as schedules por oferta, groupo e usuario
  ##
  def self.all_by_offer_id_and_group_id_and_user_id(offer_id, group_id, user_id, period = false, date_search = nil)

    date_search_option, limit, list_all_schedules = '', '', ''
    limit = 'LIMIT 2' if period

    where = []
    where << "t3.group_id = #{group_id}" unless group_id.nil?
    where << "t3.offer_id = #{offer_id}" unless offer_id.nil?
    list_all_schedules = " WHERE (#{where.join(' OR ')})" unless where.empty?

    date_search_option = "AND (t2.start_date = current_date OR t2.end_date = current_date)" if date_search.nil? and period
    date_search_option = "AND (t2.start_date = '#{date_search}' OR t2.end_date = '#{date_search}')" unless date_search.nil?

    query = <<SQL
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
    -- todas as ofertas a partir dos grupos
    cte_offers_from_groups AS (
       SELECT t2.offer_id
         FROM cte_allocations   AS t1
         JOIN groups            AS t2 ON t2.id = t1.group_id
    ),
    -- todos os grupos a partir da oferta
    cte_groups_from_offers AS (
        SELECT t3.id AS group_id
          FROM cte_allocations  AS t1
          JOIN offers           AS t2 ON t2.id = t1.offer_id
          JOIN groups           AS t3 ON t3.offer_id = t2.id
    ),
    -- juncao das allocation_tags de groups e offers
    cte_all_allocation_tags AS (
     (
        SELECT t1.id AS allocation_tag_id,
               t1.offer_id,
               t1.group_id
          FROM allocation_tags          AS t1
          JOIN cte_offers_from_groups   AS t2 ON t2.offer_id = t1.offer_id
     )
     UNION
     (
        SELECT allocation_tag_id,
               offer_id,
               group_id
          FROM cte_allocations
         WHERE group_id IS NOT NULL OR offer_id IS NOT NULL
     )
     UNION
     (
         SELECT t1.id AS allocation_tag_id,
                t1.offer_id,
                t1.group_id
           FROM allocation_tags AS t1
           JOIN cte_groups_from_offers AS t2 ON t2.group_id = t1.group_id
     )
     )
    -- consulta
   SELECT * FROM (
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date , 'discussions' AS schedule_type
          FROM discussions             AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{list_all_schedules}
           #{date_search_option}
      )
      UNION
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date, 'lessons' AS schedule_type
          FROM lessons                 AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{list_all_schedules}
           #{date_search_option}
      )
      UNION
      (
      SELECT t1.name, t1.enunciation AS description, t2.start_date, t2.end_date, 'assignments' AS schedule_type
        FROM assignments             AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{list_all_schedules}
           #{date_search_option}
      )
      UNION
      (
      SELECT t1.title AS name, t1.description, t2.start_date, t2.end_date, 'schedule_events' AS schedule_type
        FROM schedule_events         AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{list_all_schedules}
           #{date_search_option}
      )
    ) AS t1
   ORDER BY t1.end_date
   #{limit}
SQL

    ActiveRecord::Base.connection.select_all query
  end


  def self.all_by_allocations(allocations, period = false, date_search = nil)

    date_search_option, limit = '', ''
    limit = 'LIMIT 2' if period

    date_search_option = "AND (t2.start_date = current_date OR t2.end_date = current_date)" if date_search.nil? and period
    date_search_option = "AND (t2.start_date = '#{date_search}' OR t2.end_date = '#{date_search}')" unless date_search.nil?

    query = <<SQL
    WITH cte_all_allocation_tags AS (

      SELECT id AS allocation_tag_id, * FROM allocation_tags WHERE id IN (#{allocations})

     )
    -- consulta
   SELECT * FROM (
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date , 'discussions' AS schedule_type
          FROM discussions             AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{date_search_option}
      )
      UNION
      (
        SELECT t1.name, t1.description, t2.start_date, t2.end_date, 'lessons' AS schedule_type
          FROM lessons                 AS t1
          JOIN schedules               AS t2 ON t2.id = t1.schedule_id
          JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{date_search_option}
      )
      UNION
      (
      SELECT t1.name, t1.enunciation AS description, t2.start_date, t2.end_date, 'assignments' AS schedule_type
        FROM assignments             AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{date_search_option}
      )
      UNION
      (
      SELECT t1.title AS name, t1.description, t2.start_date, t2.end_date, 'schedule_events' AS schedule_type
        FROM schedule_events         AS t1
        JOIN schedules               AS t2 ON t2.id = t1.schedule_id
        JOIN cte_all_allocation_tags AS t3 ON t3.allocation_tag_id = t1.allocation_tag_id
           #{date_search_option}
      )
    ) AS t1
   ORDER BY t1.end_date
   #{limit}
SQL

    ActiveRecord::Base.connection.select_all query
  end

end
