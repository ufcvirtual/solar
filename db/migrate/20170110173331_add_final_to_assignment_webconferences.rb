class AddFinalToAssignmentWebconferences < ActiveRecord::Migration[5.1]
  def change
  	add_column :assignment_webconferences, :final, :boolean, default: false
  end
end
