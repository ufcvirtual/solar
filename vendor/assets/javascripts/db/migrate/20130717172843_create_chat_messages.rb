class CreateChatMessages < ActiveRecord::Migration
  def change
    create_table :chat_messages do |t|
      t.references :chat_room, null: false
      t.foreign_key :chat_rooms

      t.references :allocation, null: false
      t.foreign_key :allocations
      t.integer :type, null: false, default: 0 # {msg do aluno: 0, msg do sistema: 1}

      t.text :text

      t.datetime :created_at
    end
  end
end
