class RemoveDefaultFromWh < ActiveRecord::Migration[5.0]
  def up
  	change_column :allocations, :working_hours, :integer, default: nil

  	Allocation.where("final_grade is NULL AND working_hours =0").update_all working_hours: nil
  end
end
