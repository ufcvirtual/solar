class AddAssignmentsIdToIpReals < ActiveRecord::Migration[5.1]
  def change
    add_column :ip_reals, :assignment_id, :integer
    add_foreign_key :ip_reals, :assignments
  end
end
