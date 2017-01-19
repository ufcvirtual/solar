class AddTimeToAssignment < ActiveRecord::Migration
  def change
  	add_column  :assignments, :start_hour, :string
    add_column  :assignments, :end_hour, :string
  end
end
