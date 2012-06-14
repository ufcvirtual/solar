class Group < ActiveRecord::Base

  has_one :allocation_tag
  belongs_to :offer
  has_many :logs
  has_one :curriculum_unit, :through => :offer
  has_one :course, :through => :offer
  has_many :users, :through => :allocation_tag

  def code_semester
    "#{code} - #{semester}"
  end
  
  def self.find_all_by_curriculum_unit_id_and_user_id(curriculum_unit_id, user_id)
    query = "
           SELECT
            DISTINCT *
            FROM (
            ( --(cns 1 - usuarios vinculados direto a unidade curricular)
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
            ( --(cns 2 - usuarios vinculados a oferta)
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
            ( --(cns 3 - usuarios vinculados a turma)
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
            ( --(cns 4 - usuarios vinculados a graduacao)
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
