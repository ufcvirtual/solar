class ChatMessage < ActiveRecord::Base
  include SentActivity

  belongs_to :academic_allocation, -> { where academic_tool_type: 'ChatRoom' }
  belongs_to :allocation
  belongs_to :academic_allocation_user

  has_one :user, through: :allocation
  has_one :chat_room, through: :academic_allocation

  ### triggers
  trigger.after(:insert) do
    <<-SQL
      WITH ac AS (
        SELECT max_working_hours
        FROM academic_allocations
        WHERE id = NEW.academic_allocation_id AND frequency = 't' AND frequency_automatic = 't'
        LIMIT 1
      )

      UPDATE academic_allocation_users
      SET working_hours = (SELECT max_working_hours FROM ac)
      WHERE academic_allocation_users.evaluated_by_responsible != 't';
    SQL
  end
end
