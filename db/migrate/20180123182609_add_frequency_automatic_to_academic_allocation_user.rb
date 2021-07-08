class AddFrequencyAutomaticToAcademicAllocationUser < ActiveRecord::Migration[5.1]
  def change
    add_column :academic_allocation_users, :evaluated_by_responsible, :boolean, default: false
  end
end
