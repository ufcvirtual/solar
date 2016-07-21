class DropSentAssignmentTable < ActiveRecord::Migration
  def up
    AcademicAllocationUser.find_by_sql('SELECT * FROM sent_assignments').each do |sent_assignment|
      acu = AcademicAllocationUser.where(user_id: sent_assignment.user_id, group_assignment_id: sent_assignment.group_assignment_id, grade: sent_assignment.grade, academic_allocation_id: sent_assignment.academic_allocation_id).first_or_create
      
      AssignmentComment.where(sent_assignment_id: sent_assignment.id).update_all academic_allocation_user_id: acu.id
      AssignmentWebconference.where(sent_assignment_id: sent_assignment.id).update_all academic_allocation_user_id: acu.id
      AssignmentFile.where(sent_assignment_id: sent_assignment.id).update_all academic_allocation_user_id: acu.id
    end

    remove_column :assignment_files, :sent_assignment_id
    remove_column :assignment_comments, :sent_assignment_id
    remove_column :assignment_webconferences, :sent_assignment_id
    drop_table :sent_assignments
  end

  def down
  end
end
