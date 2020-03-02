class ChangeUserType < ActiveRecord::Migration[5.0]
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
