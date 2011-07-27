class ScoresTeacherController < ApplicationController

  # lista de alunos paginados
  def list

    # recupera turma selecionada
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    @students = list_students(group_id)

    @group = Group.find(group_id).code || nil

  end


  private

  def list_students(group_id)
    list = ActiveRecord::Base.connection.select_all <<SQL
    WITH cte_private_files AS (
       SELECT t1.id         AS user_id,
              COUNT(t4.id)  AS cnt_private_files
         FROM users             AS t1
    LEFT JOIN send_assignments  AS t2 ON t2.user_id = t1.id
    LEFT JOIN assignments       AS t3 ON t3.id = t2.assignment_id
    LEFT JOIN assignment_files  AS t4 ON t4.send_assignment_id = t2.id
        GROUP BY t3.id, t1.id
    )
    --
      SELECT DISTINCT t1.id,
             t1.name,
             COUNT(t7.id) AS cnt_public_files,
             t8.cnt_private_files
        FROM users              AS t1
        JOIN allocations        AS t2 ON t2.user_id = t1.id
        JOIN profiles           AS t3 ON t3.id = t2.profile_id
        JOIN allocation_tags    AS t4 ON t4.id = t2.allocation_tag_id
        JOIN groups             AS t5 ON t5.id = t4.group_id
        JOIN cte_private_files  AS t8 ON t8.user_id = t1.id
   LEFT JOIN public_files       AS t7 ON t7.allocation_tag_id = t4.id AND t7.user_id = t1.id
       WHERE t3.student = TRUE
         AND t5.id = #{group_id}
       GROUP BY t1.id, t1.name, t8.cnt_private_files
       ORDER BY t1.name, t1.id;
SQL

    return (list.nil?) ? [] : list
  end

end
