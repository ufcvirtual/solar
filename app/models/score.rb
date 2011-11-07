class Score < ActiveRecord::Base

  set_table_name "assignment_comments"

  ##
  # Recupera a quantidade de acessos de um usuario em uma unidade curricular
  ##
  def self.find_amount_access_by_student_id_and_interval(curriculum_unit_id, student_id, from_date, until_date)
    amount = ActiveRecord::Base.connection.select_all <<SQL
    SELECT COUNT(id) AS cnt_access
      FROM logs
      WHERE user_id = #{student_id}
        AND curriculum_unit_id = #{curriculum_unit_id}
        AND log_type = #{Log::TYPE[:course_access]}
        AND created_at::date BETWEEN '#{from_date}' AND '#{until_date}';
SQL

    return amount.first['cnt_access']
  end

  ##
  # Recupera historico de acessos
  ##
  def self.history_student_id_and_interval(curriculum_unit_id, student_id, from_date, until_date)
    history = ActiveRecord::Base.connection.select_all <<SQL
   SELECT t2.name               AS curriculum_unit_name,
          t1.created_at         AS access_date
     FROM logs                  AS t1
     JOIN curriculum_units      AS t2 ON t2.id = t1.curriculum_unit_id
     WHERE t2.id = #{curriculum_unit_id}
       AND t1.log_type = #{Log::TYPE[:course_access]}
       AND t1.user_id = #{student_id}
       AND t1.created_at::date BETWEEN '#{from_date}' AND '#{until_date}'
     ORDER BY t1.created_at DESC;
SQL
    return (history.nil?) ? [] : history
  end


end
