# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerChatMessagesInsertOld < ActiveRecord::Migration[5.0]
  def up
    # create_trigger("chat_messages_after_insert_row_tr", :generated => true, :compatibility => 1).
    #     on("chat_messages").
    #     after(:insert) do
    #   <<-SQL_ACTIONS
    #   WITH ac AS (
    #     SELECT max_working_hours
    #     FROM academic_allocations
    #     WHERE id = NEW.academic_allocation_id AND frequency = 't' AND frequency_automatic = 't'
    #     LIMIT 1
    #   )

    #   UPDATE academic_allocation_users
    #   SET working_hours = (SELECT max_working_hours FROM ac)
    #   WHERE academic_allocation_users.evaluated_by_responsible != 't';
    #   SQL_ACTIONS
    # end
  end

  def down
    # drop_trigger("chat_messages_after_insert_row_tr", "chat_messages", :generated => true)
  end
end
