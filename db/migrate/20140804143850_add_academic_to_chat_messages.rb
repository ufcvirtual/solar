class AddAcademicToChatMessages < ActiveRecord::Migration[5.1]
  def up
    change_table :chat_messages do |t|
      t.references :academic_allocation
      #t.index :academic_allocation_id # erro de indice ja criado, pois o metodo t:references já cria um indice para este campo
    end

    change_column :chat_messages, :chat_room_id, :integer, null: true
  end

  def down
    change_column :chat_messages, :chat_room_id, :integer, null: false
    remove_column :chat_messages, :academic_allocation_id
  end
end
