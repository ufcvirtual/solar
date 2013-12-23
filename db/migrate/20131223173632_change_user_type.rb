class ChangeUserType < ActiveRecord::Migration
	def up
    change_table :users do |t|
      t.boolean  "integrated", :default => false
    end
  end

  def down
    change_table :users do |t|
      t.remove :integrated
    end
  end
end
