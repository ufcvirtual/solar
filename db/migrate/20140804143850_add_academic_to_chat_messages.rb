class AddAcademicToChatMessages < ActiveRecord::Migration
  def up
    change_table :chat_messages do |t|
      t.references :academic_allocation
      t.index :academic_allocation_id
    end

    # ChatMessage.find_each do |msg|
    #   academic_allocations = AcademicAllocation.where(academic_tool_type: "ChatRoom", academic_tool_id: msg.chat_room_id)
    #   academic_allocations.each_with_index do |academic_allocation, idx|
    #     if idx == 0 # pessoas de turmas diferentes podem ter respondido ao mesmo chat, devemos duplicar
    #       msg.update_attribute(:academic_allocation_id, academic_allocation.id)
    #     else # duplica msgs... pessoas de turmas diferentes
    #       ChatMessage.create(msg.attributes.merge(academic_allocation_id: academic_allocation.id))
    #     end
    #   end
    # end


    change_column :chat_messages, :chat_room_id, :integer, null: true
    # remove_column :chat_messages, :chat_room_id
  end

  def down
    # change_table :chat_messages do |t|
    #   t.references :chat_room
    #   t.index :chat_room_id
    # end

    # ChatMessage.find_each do |msg|
    #   exist_copy_from_this_msg = ChatMessage.where(msg.attributes.except('id', 'academic_allocation_id', 'created_at').merge('chat_room_id' => msg.academic_allocation.academic_tool_id)).size > 0
    #   if exist_copy_from_this_msg
    #     msg.destroy
    #   else
    #     msg.update_attribute(:chat_room_id, msg.academic_allocation.academic_tool_id)
    #   end
    # end

    change_column :chat_messages, :chat_room_id, :integer, null: false
    remove_column :chat_messages, :academic_allocation_id
  end
end
