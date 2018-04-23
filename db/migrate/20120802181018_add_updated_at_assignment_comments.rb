class AddUpdatedAtAssignmentComments < ActiveRecord::Migration[5.0]
  def up
  	add_column :assignment_comments, :updated_at, :datetime
  end

  def down
  	remove_column :assignment_comments, :updated_at
  end
end
