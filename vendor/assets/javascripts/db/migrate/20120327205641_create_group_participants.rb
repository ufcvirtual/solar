class CreateGroupParticipants < ActiveRecord::Migration
  def self.up
    create_table :group_participants do |t|
      t.integer  :group_assignment_id, :null => false
      t.integer  :user_id, :null => false
      t.datetime :participant_updated_at
    end

    add_foreign_key(:group_participants, :group_assignments)
    add_foreign_key(:group_participants, :users)
  end

  def self.down
    drop_table :group_participants
  end
end
