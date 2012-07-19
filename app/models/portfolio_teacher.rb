class PortfolioTeacher < ActiveRecord::Base

  self.table_name = "assignment_comments"

  ##
  # Lista de alunos presentes nas turmas
  ##
  def self.list_students_by_allocations(allocations)
    query = <<SQL
      SELECT DISTINCT t3.id,
             initcap(t3.name) AS name
        FROM allocations      AS t1
        JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
        JOIN users            AS t3 ON t3.id = t1.user_id
        JOIN profiles         AS t4 ON t4.id = t1.profile_id
       WHERE t2.id IN (#{allocations})
         AND cast( t4.types & '#{Profile_Type_Student}' as boolean) 
         AND t1.status = #{Allocation_Activated}
         AND t2.group_id IS NOT NULL
       ORDER BY name
SQL

    ActiveRecord::Base.connection.select_all query
  end

end
