class Profile < ActiveRecord::Base

  has_many :allocations
  has_many :users, :through => :allocations
  has_many :permissions_resources
  has_many :permissions_menus

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

    return self.find_by_sql(query)
  end

  # Verifica se o usuario tem o perfil de estudante
  def self.student?(user_id = 0)
    types_perfil(user_id).include?('student')
  end

  # Verifica se o usuario tem o perfil de responsavel
  def self.class_responsible?(user_id = 0)
    types_perfil(user_id).include?('class_responsible')
  end

  # Verifica se é estudante ou responsal
  def self.types_perfil(user_id)
    query = <<SQL
       SELECT DISTINCT
              CASE
                  WHEN      cast( t3.types & '#{Profile_Type_Student}' as boolean)    IS TRUE THEN 'student'
                  WHEN      cast( t3.types & '#{Profile_Type_Class_Responsible}' as boolean)  IS TRUE THEN 'class_responsible'
                  ELSE 'undefined'
              END AS type_perfil
         FROM users         AS t1
         JOIN allocations   AS t2 ON t2.user_id = t1.id
         JOIN profiles      AS t3 ON t3.id = t2.profile_id
        WHERE t1.id = #{user_id};
SQL

    tps = ActiveRecord::Base.connection.select_all query
    tps = [] if tps.nil?

    # Transformando o hash da consulta em um array
    array_types = []
    tps.each do |tp|
      array_types << tp.values.first
    end

    return array_types
  end

  ##
  # Verifica se o usuário é responsável pela turma do arquivo que acessa (NÃO CONCLUÍDO)
  ##
  def self.user_responsible_of_class(allocation_tag_id, user_id)
    # coleta todas as allocations_tags relacinadas à turma em questão, pois um responsável pode não estar associado diretamente a ela
    related_allocations_tags = AllocationTag.find_related_ids(allocation_tag_id)
    user_is_responsible = false
    for allocation_tag in related_allocations_tags
      # para cada allocation_tag, verifica se o usuário está relacionado à ela
      allocation_user = Allocation.find_by_allocation_tag_id_and_user_id(allocation_tag, user_id)
      unless allocation_user.nil?
        # verifica se sua relação com tal allocation é de responsável
        if allocation_user.profile.types == Profile_Type_Class_Responsible
          user_is_responsible = true
          break
        end
      end
    end
    return user_is_responsible
  end

end