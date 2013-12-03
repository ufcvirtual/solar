class ChangeProfile < ActiveRecord::Migration
	def up
    change_table :profiles do |t|
      t.string :description, limit: 500
    end
  end

  def down
    change_table :profiles do |t|
      t.remove :description
    end
  end
end
