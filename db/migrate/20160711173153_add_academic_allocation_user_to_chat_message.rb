class AddAcademicAllocationUserToChatMessage < ActiveRecord::Migration
  def change
    add_column :chat_messages, :academic_allocation_user_id, :integer
  end
end
