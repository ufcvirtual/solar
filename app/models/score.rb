class Score < ActiveRecord::Base

  set_table_name "assignment_comments"

  # Recupera a quantidade de acessos de um usuario em uma unidade curricular
  def self.find_amount_access_by_student_id_and_interval(student_id, from_date, until_date)
    amount = ActiveRecord::Base.connection.select_all <<SQL
    SELECT COUNT(t2.id) AS cnt_access
      FROM users    AS t1
      JOIN logs     AS t2 ON t1.id = t2.user_id
      WHERE t1.id = #{student_id}
        AND log_type = #{Log::TYPE[:course_access]}
        AND t2.created_at::date BETWEEN '#{from_date}' AND '#{until_date}';
SQL

    return amount.first['cnt_access']
  end

end
