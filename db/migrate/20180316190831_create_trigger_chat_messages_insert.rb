# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerChatMessagesInsert < ActiveRecord::Migration[5.0]
  def up
    create_trigger("chat_messages_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("chat_messages").
        after(:insert) do
      <<-SQL_ACTIONS
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
      SQL_ACTIONS
    end
  end

  def down
    drop_trigger("chat_messages_after_insert_row_tr", "chat_messages", :generated => true)
  end
end
