class AddWhToAllocations < ActiveRecord::Migration
  def up
    add_column :allocations, :working_hours, :integer, default: 0

    allocations = Allocation.find_by_sql <<-SQL
      SELECT DISTINCT al.id 
      FROM allocations al
      JOIN related_taggables rt        ON rt.group_at_id = al.allocation_tag_id
      JOIN academic_allocations ac     ON ac.allocation_tag_id = rt.group_at_id OR ac.allocation_tag_id = rt.offer_at_id OR ac.allocation_tag_id = rt.curriculum_unit_at_id OR ac.allocation_tag_id = rt.course_at_id OR ac.allocation_tag_id = rt.curriculum_unit_type_at_id
      JOIN academic_allocation_users acu ON acu.academic_allocation_id = ac.id
      LEFT JOIN group_participants gp ON gp.group_assignment_id = acu.group_assignment_id
      WHERE (acu.user_id = al.user_id OR gp.user_id = al.user_id) AND acu.working_hours IS NOT NULL;
    SQL

    Allocation.where(id: allocations.map(&:id)).map(&:calculate_working_hours)
  end

  def down
    remove_column :allocations, :working_hours
  end
end
