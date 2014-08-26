class AddAcademicToChatMessages < ActiveRecord::Migration
  def up
    change_table :chat_messages do |t|
      t.references :academic_allocation
      t.index :academic_allocation_id
    end

    change_column :chat_messages, :chat_room_id, :integer, null: true
  end

  def down
    change_column :chat_messages, :chat_room_id, :integer, null: false
    remove_column :chat_messages, :academic_allocation_id
  end
end
