class Enrollment < ActiveRecord::Base
  belongs_to :offer

  def self.enrollments_of_user(user, profile, offer_category = nil, curriculum_unit_name = nil)
    query_category, query_text = ''
    query_category = " and t.id = #{offer_category}" unless offer_category.nil? or offer_category.empty?
    query_text     = " and lower(cr.name) ~ lower('#{curriculum_unit_name}')" unless curriculum_unit_name.nil? or curriculum_unit_name.empty?

    query_enroll =
      " SELECT DISTINCT of.id, cr.name as name, t.id AS categoryid, t.description AS categorydesc,
               t.allows_enrollment, al.status AS status, al.id AS allocationid,
               g.code, e.start, e.end, atg.id AS allocationtagid,
               g.id AS groupsid, t.icon_name, of.semester
          FROM allocations al
          JOIN allocation_tags atg      ON atg.id = al.allocation_tag_id
          JOIN groups g                 ON g.id = atg.group_id
          JOIN offers of                ON of.id = g.offer_id
          JOIN curriculum_units cr      ON cr.id = of.curriculum_unit_id
          JOIN curriculum_unit_types t  ON t.id = cr.curriculum_unit_type_id
     LEFT JOIN enrollments e            ON of.id = e.offer_id
         WHERE al.user_id = #{user.id}
           AND al.profile_id = #{profile}
           AND al.status = #{Allocation_Activated} 
           #{query_category}
           #{query_text}
           ORDER BY name"

    Offer.find_by_sql(query_enroll)
  end

  def self.all_enrollments_by_user(user, profile, offer_category = nil, curriculum_unit_name = nil)
    query_category, query_text = ''
    query_category = " and t.id = #{offer_category}" unless offer_category.nil? or offer_category.empty?
    query_text     = " and lower(cr.name) ~ lower('#{curriculum_unit_name}')" unless curriculum_unit_name.nil? or curriculum_unit_name.empty?

    query_offer = "
      WITH cte_enrollments_of_user AS (
          SELECT DISTINCT of.id,
                 of.semester,
                 cr.name as name,
                 t.id AS categoryid,
                 t.description AS categorydesc,
                 t.allows_enrollment,
                 al.status AS status,
                 al.id AS allocationid,
                 g.code,
                 e.start,
                 e.end,
                 atg.id AS allocationtagid,
                 g.id AS groupsid, t.icon_name
            FROM allocations al
            JOIN allocation_tags atg      ON atg.id = al.allocation_tag_id
            JOIN groups g                 ON g.id = atg.group_id
            JOIN offers of                ON of.id = g.offer_id
            JOIN curriculum_units cr      ON cr.id = of.curriculum_unit_id
            JOIN curriculum_unit_types t  ON t.id = cr.curriculum_unit_type_id
        LEFT JOIN enrollments e           ON of.id = e.offer_id
           WHERE al.user_id = #{user.id}
             AND al.profile_id = #{profile}
             #{query_category}
             #{query_text}
        )
        --
        (
          SELECT DISTINCT of.id,
                 of.semester,
                 cr.name as name,
                 t.id as categoryid,
                 t.description as categorydesc,
                 t.allows_enrollment,
                 null::integer as status,
                 null::integer as allocationid,
                 g.code,
                 e.start,
                 e.end,
                 atg.id as allocationtagid,
                 g.id AS groupsid,
                 t.icon_name
            FROM offers of
       LEFT JOIN enrollments e           ON of.id = e.offer_id
      INNER JOIN curriculum_units cr     ON of.curriculum_unit_id = cr.id
      INNER JOIN curriculum_unit_types t ON t.id = cr.curriculum_unit_type_id
 LEFT OUTER JOIN courses c               ON of.course_id = c.id
      INNER JOIN groups g                ON g.offer_id = of.id
      INNER JOIN allocation_tags atg     ON atg.group_id = g.id
            WHERE (select enrollments.start from enrollments where of.id = enrollments.offer_id) <= current_date
              AND (select enrollments.end from enrollments where of.id = enrollments.offer_id) >= current_date
              AND t.allows_enrollment = TRUE
              AND NOT EXISTS
                (
                  SELECT al.id
                     FROM allocations al
               INNER JOIN allocation_tags ON allocation_tags.id = al.allocation_tag_id
               INNER JOIN groups          ON groups.id = allocation_tags.group_id
               INNER JOIN offers          ON offers.id = groups.offer_id
                    WHERE user_id = #{user.id}
                      AND offers.id = of.id
                )
              #{query_category}
              #{query_text}
        )
        UNION
        SELECT * FROM cte_enrollments_of_user"

    Offer.find_by_sql(query_offer)
  end

end
