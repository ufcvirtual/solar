class AddFinalToAssignmentWebconferences < ActiveRecord::Migration
  def change
  	add_column :assignment_webconferences, :final, :boolean, default: false
  end
end
