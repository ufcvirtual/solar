class AddAcIdToAllocationTag < ActiveRecord::Migration[5.1]
  def change
  	add_column :allocation_tags, :situation_date_ac_id, :integer
  end
end
