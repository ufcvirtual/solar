class AddcademicAllocationUserToAssigmentWebConference < ActiveRecord::Migration
 def change
    add_column :assignment_webconferences, :academic_allocation_user_id, :integer
  end
end
