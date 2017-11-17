class SetDefaultSituationToAllocations < ActiveRecord::Migration
  def up
  	change_column :allocations, :grade_situation, :integer

  	Allocation.where(profile_id: 1).update_all grade_situation: 6
  end
end
