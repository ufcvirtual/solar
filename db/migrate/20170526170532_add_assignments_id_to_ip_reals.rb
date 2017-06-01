class AddAssignmentsIdToIpReals < ActiveRecord::Migration
  def change
    add_column :ip_reals, :assignment_id, :integer
    add_foreign_key :ip_reals, :assignments
  end
end
