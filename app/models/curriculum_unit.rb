class CurriculumUnit < ActiveRecord::Base

  has_one :allocation_tag
  has_many :offers


  #CORRIGIR O NUMERO MÀXIMO DE RESULTADOS
  def self.select_for_schedule_in_portlet(group_id, user_id,curriculum_unit_id )
    ActiveRecord::Base.connection.select_all  <<SQL
    SELECT * FROM (
      (    SELECT t1.name, t1.description, t4.start_date,t4.end_date , 'discussions' AS schedule_type
      FROM discussions AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND (t2.group_id = #{group_id} OR t2.curriculum_unit_id = #{curriculum_unit_id})
      AND (current_date = t4.start_date OR current_date = t4.end_date)
      )
      union
      (    SELECT t1.name, t1.description, t4.start_date,t4.end_date, 'lessons' AS schedule_type
      FROM lessons AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND (t2.group_id = #{group_id} OR t2.curriculum_unit_id = #{curriculum_unit_id})
      AND (current_date = t4.start_date OR current_date = t4.end_date)
      )
      union
      (
      SELECT t1.name,t1.enunciation AS description, t1.start_date,t1.end_date, 'assignments' AS schedule_type
      FROM assignments AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND (t2.group_id = #{group_id} OR t2.curriculum_unit_id = #{curriculum_unit_id})
      AND (current_date = t4.start_date OR current_date = t4.end_date)
      )
      union
      (
      SELECT t1.title AS name,t1.description,t4.start_date,t4.end_date, 'schedule_events' AS schedule_type
      FROM schedule_events AS t1
      JOIN schedules       AS t4 ON t1.schedule_id = t4.id
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN allocations     AS t3 ON t3.allocation_tag_id = t2.id
      WHERE t3.user_id = #{user_id}
      AND (t2.group_id = #{group_id} OR t2.curriculum_unit_id = #{curriculum_unit_id})
      AND (current_date = t4.start_date OR current_date = t4.end_date)
      )
) AS final

ORDER BY final.name
LIMIT 3

SQL
  end

  def self.find_user_groups_by_curriculum_unit(curriculum_unit_id, user_id)
    query = "
           SELECT
            DISTINCT *
            FROM (
            (	--(cns 1 - usuarios vinculados direto a unidade curricular)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN curriculum_units cr ON cr.id = tg.curriculum_unit_id
                INNER JOIN offers of ON of.curriculum_unit_id = cr.id
                INNER JOIN groups gr ON gr.offer_id = of.id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
            union
            (	--(cns 2 - usuarios vinculados a oferta)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN offers of ON of.id = tg.offer_id
                INNER JOIN groups gr ON gr.offer_id = of.id
                INNER JOIN curriculum_units cr ON cr.id = of.curriculum_unit_id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
            union
            (	--(cns 3 - usuarios vinculados a turma)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN groups gr ON gr.id = tg.group_id
                INNER JOIN offers of ON of.id = gr.offer_id
                INNER JOIN curriculum_units cr ON cr.id = of.curriculum_unit_id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
            union
            (	--(cns 4 - usuarios vinculados a graduacao)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN courses cs ON cs.id = tg.course_id
                INNER JOIN offers of ON of.course_id = cs.id
                INNER JOIN groups gr ON gr.offer_id = of.id
                INNER JOIN curriculum_units cr ON cr.id = of.curriculum_unit_id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
          ) AS ucs_do_usuario
          ORDER BY semester DESC, code"
    groups1 = Group.find_by_sql(query)
    return (groups1.nil?) ? [] : groups1
  end

end
