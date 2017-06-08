class RenameAssignmentController < ActiveRecord::Migration
  def up
  	rename_column :assignments, :controller, :controlled
  end

  def down
  	rename_column :assignments, :controlled, :controller
  end
end
