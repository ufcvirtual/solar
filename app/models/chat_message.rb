class ChatMessage < ActiveRecord::Base
  include SentActivity

  belongs_to :academic_allocation, -> { where academic_tool_type: 'ChatRoom' }
  belongs_to :allocation
  belongs_to :academic_allocation_user

  has_one :user, through: :allocation
  has_one :chat_room, through: :academic_allocation

  attr_accessor :merge

  ### triggers
  # chats are not yet created by activerecord, so this trigger must relate the chatMessage to an ACU.
  # must see if exists acu; if dont, create; if does, change status
  # must see if ac must have automatic frequency; if does, add frequency and status
  trigger.after(:insert) do
    <<-SQL
      DECLARE
        ac Decimal;
       acu integer;

      BEGIN

      SELECT max_working_hours INTO ac
       FROM academic_allocations
        WHERE academic_allocations.id = NEW.academic_allocation_id AND frequency = 't' AND frequency_automatic = 't'
        LIMIT 1;

        SELECT id INTO acu
        FROM academic_allocation_users
        WHERE academic_allocation_users.academic_allocation_id = NEW.academic_allocation_id
        AND academic_allocation_users.user_id = NEW.user_id
        LIMIT 1;

        IF (acu IS NOT NULL AND ac IS NOT NULL) THEN
          UPDATE academic_allocation_users
          SET working_hours = ac, status = 2
          WHERE academic_allocation_users.evaluated_by_responsible != 't'
          AND academic_allocation_users.id = acu;
        ELSIF (ac IS NOT NULL) THEN
          INSERT INTO academic_allocation_users (user_id, academic_allocation_id, working_hours, status) VALUES(NEW.user_id, NEW.academic_allocation_id, ac, 2);
        ELSIF (acu IS NULL) THEN
          INSERT INTO academic_allocation_users (user_id, academic_allocation_id, status) VALUES(NEW.user_id, NEW.academic_allocation_id, 1);
          UPDATE chat_messages SET academic_allocation_user_id = (SELECT id FROM academic_allocation_users WHERE user_id = NEW.user_id AND  academic_allocation_id = NEW.academic_allocation_id) WHERE id = NEW.id;
        END IF;
      END;
    SQL
  end
end
