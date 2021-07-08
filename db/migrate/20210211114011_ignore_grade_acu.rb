class IgnoreGradeAcu < ActiveRecord::Migration[5.0]
  def change
        add_column :academic_allocation_users, :ignore, :boolean, default: false
  end
end
