class AddTimestampsToUserMessages < ActiveRecord::Migration
  def change
  	change_table :user_messages do |t|
      t.timestamps
    end
  end
end
