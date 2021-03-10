class AddAcademicAllocationUserToChatMessage < ActiveRecord::Migration[5.1]
  def change
    add_column :chat_messages, :academic_allocation_user_id, :integer
  end
end
