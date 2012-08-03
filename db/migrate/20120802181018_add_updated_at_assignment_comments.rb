class AddUpdatedAtAssignmentComments < ActiveRecord::Migration
  def up
  	add_column :assignment_comments, :updated_at, :datetime
  end

  def down
  	remove_column :assignment_comments, :updated_at
  end
end
