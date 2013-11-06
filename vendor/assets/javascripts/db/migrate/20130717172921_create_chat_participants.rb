class CreateChatParticipants < ActiveRecord::Migration
  def change
    create_table :chat_participants, id: false do |t|
      t.references :chat_room, null: false
      t.foreign_key :chat_rooms

      t.references :allocation, null: false
      t.foreign_key :allocations
    end

    add_index :chat_participants, [:chat_room_id, :allocation_id], unique: true
  end
end
