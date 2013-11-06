class AlterSendAssignmentAndAssignmentFileTables < ActiveRecord::Migration
  def up
  	change_column :send_assignments, :user_id, :integer, :null => true
  	add_column :assignment_files, :user_id, :integer, :default => 1, :null => true

  	AssignmentFile.all.each{ |assignment_file| 
  		send_assignment = SendAssignment.find(assignment_file.send_assignment_id)
  		assignment_file.update_attribute(:user_id, send_assignment.user_id)
  	}


  end

  def down
  	change_column :send_assignments, :user_id, :integer, :null => false
  	remove_column :assignment_files, :user_id
  end
end
