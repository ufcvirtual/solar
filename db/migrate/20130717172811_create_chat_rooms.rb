class CreateChatRooms < ActiveRecord::Migration
  def change

    create_table :chat_rooms do |t|
      t.integer :type, null: false, default: 0 # {todos: 0, grupo: 1}
      t.string :title, null: false
      t.text :description
      
      t.references :schedule, null: false
      t.foreign_key :schedules

      t.string :start_hour
      t.string :end_hour
    end

  end
end
