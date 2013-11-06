class ChangeUserChangeStatusType < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.boolean :active, default: true, null: false
      t.remove :status
    end
  end

  def down
    change_table :users do |t|
      t.remove :active
      t.string :status, limit: 1
    end
  end
end
