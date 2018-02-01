class CreateNotificationMails < ActiveRecord::Migration
  def up
  	create_table :notification_mails do |table|
      table.integer :user_id, null: false 
      table.boolean :message, default: true, null: false 
      table.boolean :post, default: true, null: false
      table.boolean :exam, default: true, null: false                           
      table.foreign_key :users        	           
      table.timestamps 
    end  
  end

  def down
  end
end