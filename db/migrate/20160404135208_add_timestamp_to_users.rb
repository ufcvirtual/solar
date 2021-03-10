class AddTimestampToUsers < ActiveRecord::Migration[5.1]
  def change
    change_table :users do |t|
      t.timestamps
    end
  end
end
