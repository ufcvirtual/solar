class IgnoreGradeAcu < ActiveRecord::Migration
  def change
        add_column :academic_allocation_users, :ignore, :boolean, default: false
  end
end
