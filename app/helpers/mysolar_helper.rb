module MysolarHelper

  def load_curriculum_unit_data
    if current_user
      query_current_courses =
        "SELECT  DISTINCT ON (id, name) * from (
      select * from (
      (
        select cr.*, NULL AS offer_id, NULL::integer AS group_id, NULL::varchar AS semester --(cns 1 - usuarios vinculados direto a unidade curricular)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tag_id
          inner join curriculum_units cr on cr.id = tg.curriculum_unit_id
        where
          user_id = #{current_user.id} AND al.status = #{Allocation_Activated}
      )
      union
      (
        select cr.*, of.id AS offer_id, NULL::integer AS group_id, semester --(cns 2 - usuarios vinculados a oferta)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tag_id
          inner join offers of on of.id = tg.offer_id
          inner join curriculum_units cr on cr.id = of.curriculum_unit_id
        where
          user_id = #{current_user.id} AND al.status = #{Allocation_Activated}
      )
      union(
        select cr.*, of.id AS offer_id, gr.id AS group_id, semester --(cns 3 - usuarios vinculados a turma)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tag_id
          inner join groups gr on gr.id = tg.group_id
          inner join offers of on of.id = gr.offer_id
          inner join curriculum_units cr on cr.id = of.curriculum_unit_id
        where
          user_id = #{current_user.id} AND al.status = #{Allocation_Activated}
      )
      union
      (
        select cr.*, of.id AS offer_id, NULL::integer AS group_id, semester --(cns 3 - usuarios vinculados a graduacao)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tag_id
          inner join courses cs on cs.id = tg.course_id
          inner join offers of on of.course_id = cs.id
          inner join curriculum_units cr on cr.id = of.curriculum_unit_id
        where
          user_id = #{current_user.id} AND al.status = #{Allocation_Activated}
        )
      ) as user_crs
      order by name, semester DESC, id ) as user_ordered_crs"

      ActiveRecord::Base.connection.select_all query_current_courses
    end
  end

end
