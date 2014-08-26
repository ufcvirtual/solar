class AddAcademicToChatParticipants < ActiveRecord::Migration
  def up
    change_table :chat_participants do |t|
      t.references :academic_allocation
      t.index :academic_allocation_id
    end

    execute "DROP INDEX IF EXISTS index_chat_participants_on_chat_room_id_and_allocation_id;"

    ChatParticipant.find_each do |part|
      academic_allocations = AcademicAllocation.where(academic_tool_type: 'ChatRoom', academic_tool_id: part.chat_room_id)

      academic_allocations.each_with_index do |academic_allocation, idx|
        if idx == 0 # pessoas de turmas diferentes podem ter ficado no mesmo chat, devemos duplicar
          part.update_attribute(:academic_allocation_id, academic_allocation.id)
        else # duplica participantes... pessoas de turmas diferentes
          ChatParticipant.create(part.attributes.merge(academic_allocation_id: academic_allocation.id))
        end
      end
    end

    remove_column :chat_participants, :chat_room_id
  end

  def down
    change_table :chat_participants do |t|
      t.references :chat_room
      t.index :chat_room_id
    end

    ChatParticipant.find_each do |part|
      exist_copy_from_this_part = ChatParticipant.where(part.attributes.except('id', 'academic_allocation_id', 'created_at').merge('chat_room_id' => part.academic_allocation.academic_tool_id)).size > 0
      if exist_copy_from_this_part
        part.destroy
      else
        part.update_attribute(:chat_room_id, part.academic_allocation.academic_tool_id)
      end
    end

    remove_column :chat_participants, :academic_allocation_id
  end
end
