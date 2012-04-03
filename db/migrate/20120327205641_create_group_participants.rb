class CreateGroupParticipants < ActiveRecord::Migration
  def self.up
    create_table :group_participants do |t|
      t.integer  :group_assignment_id, :null => false
      t.integer  :user_id, :null => false
      t.datetime :participant_updated_at
    end
  end

  def self.down
    drop_table :group_participants
  end
end
