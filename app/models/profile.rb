class Profile < ActiveRecord::Base

  has_many :allocation
  has_many :permissions_resource
  has_many :permissions_menu

  # Recupera perfis do usuario dependendo da allocation_tag
  def self.find_by_allocation_tag_and_user_id(activity_allocation_tag_id, user_id)
    query = "WITH cte_hierarchy AS (
    SELECT root.id AS allocation_tag_id,
           CASE
             WHEN group_id  IS NOT NULL THEN 'GROUP'::text
             WHEN offer_id  IS NOT NULL THEN 'OFFER'::text
             WHEN course_id IS NOT NULL THEN 'COURSE'::text
             ELSE 'CURRICULUM_UNIT'::text
           END as entity_type,
           (COALESCE(group_id, 0) + COALESCE(offer_id, 0) + COALESCE(curriculum_unit_id, 0) + COALESCE(course_id, 0)) as entity_id,
           --parents do tipo offer
           CASE
             WHEN group_id IS NOT NULL THEN (
                 SELECT COALESCE(t.id, 0)
                   FROM groups          g
              LEFT JOIN allocation_tags t ON t.offer_id = g.offer_id
                  WHERE g.id = root.group_id
             )
             ELSE 0
           END as offer_parent_tag_id,
           --parents do tipo curriculum unit
           CASE
             WHEN group_id IS NOT NULL THEN (
                 SELECT COALESCE(t.id, 0)
                   FROM groups          g
              LEFT JOIN offers          o ON g.offer_id = o.id
              LEFT JOIN allocation_tags t ON t.curriculum_unit_id = o.curriculum_unit_id
                  WHERE g.id = root.group_id
             )
             WHEN offer_id IS NOT NULL THEN (
                 SELECT COALESCE(t.id, 0)
                   FROM offers          o
              LEFT JOIN allocation_tags t ON t.curriculum_unit_id = o.curriculum_unit_id
                  WHERE o.id = root.offer_id
             )
             ELSE 0
           END as curriculum_unit_parent_tag_id,
           --parents do tipo course
           CASE
             WHEN group_id IS NOT NULL THEN (
                 SELECT COALESCE(t.id,0)
                   FROM groups g
              LEFT JOIN offers o on g.offer_id = o.id
              LEFT JOIN allocation_tags t on t.course_id = o.course_id
                  WHERE g.id = root.group_id
             )
             WHEN offer_id IS NOT NULL THEN (
                 SELECT COALESCE(t.id, 0)
                   FROM offers o
              LEFT JOIN allocation_tags t on t.course_id = o.course_id
                  WHERE o.id = root.offer_id
             )
             ELSE (SELECT 0)
           END as course_parent_tag_id
    FROM allocation_tags root
   ORDER BY entity_type, allocation_tag_id
  )
  --
    SELECT DISTINCT p.*
      FROM allocations      al
      JOIN profiles         p  ON al.profile_id = p.id
      JOIN cte_hierarchy    ch ON (
           (al.allocation_tag_id = ch.allocation_tag_id) OR
           (al.allocation_tag_id = ch.offer_parent_tag_id) OR
           (al.allocation_tag_id = ch.curriculum_unit_parent_tag_id) OR
           (al.allocation_tag_id = ch.course_parent_tag_id))
    WHERE al.user_id = #{user_id}
      AND al.status = #{Allocation_Activated}
      AND (
            (ch.allocation_tag_id = #{activity_allocation_tag_id}) OR
            (ch.offer_parent_tag_id = #{activity_allocation_tag_id}) OR
            (ch.curriculum_unit_parent_tag_id = #{activity_allocation_tag_id}) OR
            (ch.course_parent_tag_id = #{activity_allocation_tag_id})
          )"

    return Profile.find_by_sql(query)
  end

end
