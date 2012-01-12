class SupportMaterialFileEditor < ActiveRecord::Base

  set_table_name "support_material_file"

  def self.list_editor_option(current_user)

   query =  <<SQL 
  SELECT DISTINCT
        t1.user_id, t1.allocation_tag_id, t2.group_id, t3.offer_id, t3.code, t4.semester, t4.curriculum_unit_id, t5.name, t6.name, t6.code
        FROM allocations AS t1
            JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
            JOIN groups AS t3 ON t3.offer_id = t2.group_id
            JOIN offers AS t4 ON t4.id = t3.offer_id
            JOIN curriculum_units AS t5 ON t5.id = t4.curriculum_unit_id
            JOIN courses AS t6 ON t6.id = t4.course_id
        WHERE t1.user_id IN (#{current_user});

SQL

    ActiveRecord::Base.connection.select_all query
    
  end
#
#  def self.list_editor_by_curriculum_unit(curriculun_unit_id)
#    query <<SQL
#    SELECT DISTINCT 
      t1.
      FROM
#SQL
#
#  end
#
#  def self.list_editor_by_course
#  end

end
