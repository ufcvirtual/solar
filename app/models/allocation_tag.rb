class AllocationTag < ActiveRecord::Base

  has_many :allocations
  has_many :lessons
  has_many :discussions
  has_many :schedule_events
  has_many :assignments

  belongs_to :group
  belongs_to :offer
  belongs_to :curriculum_unit
  belongs_to :course

  #Retorna ids de AllocationTags relacionadas.
  def self.find_related_ids(allocation_tag_id)
    hierarchy = ActiveRecord::Base.connection.select_all <<SQL
      select allocation_tag_id, offer_parent_tag_id, curriculum_unit_parent_tag_id, course_parent_tag_id from
      (select
        root.id as allocation_tag_id,
        CASE
          WHEN group_id is not null THEN (select 'GROUP'::text)
          WHEN offer_id is not null THEN (select 'OFFER'::text)
          WHEN course_id is not null THEN (select 'COURSE'::text)
          ELSE (select 'CURRICULUM_UNIT'::text)
        END as entity_type,

        (coalesce(group_id, 0) + coalesce(offer_id, 0) + coalesce(curriculum_unit_id, 0) + coalesce(course_id, 0)) as entity_id,

        --parents do tipo offer
         CASE
           WHEN group_id is not null THEN (
             select coalesce(t.id,0)
             from
         groups g
         left join allocation_tags t on t.offer_id = g.offer_id
             where
         g.id = root.group_id
           )
           ELSE (select 0)
         END as offer_parent_tag_id,

         --parents do tipo curriculum unit
         CASE
           WHEN group_id is not null THEN (
             select coalesce(t.id,0)
             from
         groups g
         left join offers o on g.offer_id = o.id
         left join allocation_tags t on t.curriculum_unit_id = o.curriculum_unit_id
             where
         g.id = root.group_id
           )
           WHEN offer_id is not null THEN (
             select coalesce(t.id,0)
             from
         offers o
         left join allocation_tags t on t.curriculum_unit_id = o.curriculum_unit_id
             where
         o.id = root.offer_id
           )
           ELSE (select 0)
         END as curriculum_unit_parent_tag_id,

         --parents do tipo course
         CASE
           WHEN group_id is not null THEN (
             select coalesce(t.id,0)
             from
         groups g
         left join offers o on g.offer_id = o.id
         left join allocation_tags t on t.course_id = o.course_id
             where
         g.id = root.group_id
           )
           WHEN offer_id is not null THEN (
             select coalesce(t.id,0)
             from
         offers o
         left join allocation_tags t on t.course_id = o.course_id
             where
         o.id = root.offer_id
           )
           ELSE (select 0)
         END as course_parent_tag_id
      FROM
        allocation_tags root
      ) as hierarchy
      where
        (hierarchy.allocation_tag_id = #{allocation_tag_id}) or
        (hierarchy.offer_parent_tag_id = #{allocation_tag_id}) or
        (hierarchy.curriculum_unit_parent_tag_id = #{allocation_tag_id}) or
        (hierarchy.course_parent_tag_id = #{allocation_tag_id})
SQL

    result = Array.new()
    hierarchy.each do |line|
      result << line["allocation_tag_id"].to_i
      result << line["offer_parent_tag_id"].to_i
      result << line["curriculum_unit_parent_tag_id"].to_i
      result << line["course_parent_tag_id"].to_i
    end

    return result.flatten.uniq

  end

  def self.find_all_groups(allocations = [])

    query = <<SQL
         SELECT t2.id, t2.code, t3.semester
           FROM allocation_tags AS t1
           JOIN groups          AS t2 ON t1.group_id = t2.id
           JOIN offers          AS t3 ON t2.offer_id = t3.id
          WHERE t1.group_id IS NOT NULL
            AND t1.id IN (#{allocations.join(',')})
SQL

    Group.find_by_sql(query)

  end

end
