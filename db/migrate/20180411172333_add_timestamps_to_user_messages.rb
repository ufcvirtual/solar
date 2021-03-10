class AddTimestampsToUserMessages < ActiveRecord::Migration[5.1]
  def change
  	change_table :user_messages do |t|
      t.timestamps
    end
  end
end
