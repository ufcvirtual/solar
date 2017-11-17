class AddAcIdToAllocationTag < ActiveRecord::Migration
  def change
  	add_column :allocation_tags, :situation_date_ac_id, :integer
  end
end
