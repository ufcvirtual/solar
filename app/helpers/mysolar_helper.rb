module MysolarHelper

  #Recebendo um código de um portlet, escolhe qual deve ser renderizado.
  def show_portlet(portlet_code = nil)

    case portlet_code
    when "1"
      render '/portlets/curricular_unit'
    when "2"
      render '/portlets/lessons'
    when "3"
      render '/portlets/recent_activities'
    when "4"
      render '/portlets/calendar'
    when "5"
      render '/portlets/forum'
    when "6"
      render '/portlets/news'
    else
      ""
    end
  end

  def load_curriculum_unit_data
    if current_user
      query_current_courses =
        "select DISTINCT ON (id, name) * from (
      (
        select cr.*, NULL AS offers_id, NULL::integer AS groups_id --(cns 1 - usuarios vinculados direto a unidade curricular)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tags_id
          inner join curriculum_units cr on cr.id = tg.curriculum_units_id
        where
          users_id = #{current_user.id} AND al.status = #{Allocation_Activated}
      )
      union
      (
        select cr.*, of.id AS offers_id, NULL::integer AS groups_id --(cns 2 - usuarios vinculados a oferta)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tags_id
          inner join offers of on of.id = tg.offers_id
          inner join curriculum_units cr on cr.id = of.curriculum_units_id
        where
          users_id = #{current_user.id} AND al.status = #{Allocation_Activated}
      )
      union(
        select cr.*, of.id AS offers_id, gr.id AS groups_id --(cns 3 - usuarios vinculados a turma)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tags_id
          inner join groups gr on gr.id = tg.groups_id
          inner join offers of on of.id = gr.offers_id
          inner join curriculum_units cr on cr.id = of.curriculum_units_id
        where
          users_id = #{current_user.id} AND al.status = #{Allocation_Activated}
      )
      union
      (
        select cr.*, of.id AS offers_id, NULL::integer AS groups_id --(cns 3 - usuarios vinculados a graduacao)
        from
          allocations al
          inner join allocation_tags tg on tg.id = al.allocation_tags_id
          inner join courses cs on cs.id = tg.courses_id
          inner join offers of on of.courses_id = cs.id
          inner join curriculum_units cr on cr.id = of.curriculum_units_id
        where
          users_id = #{current_user.id} AND al.status = #{Allocation_Activated}
        )
      ) as ucs_do_usuario
      order by name, id"

      conn = ActiveRecord::Base.connection
      conn.select_all query_current_courses
    end
  end

end
