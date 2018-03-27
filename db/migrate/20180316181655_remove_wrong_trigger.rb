class RemoveWrongTrigger < ActiveRecord::Migration
  def change
    begin
      drop_trigger("chat_messages_after_insert_row_tr", "chat_messages", :generated => true)
    rescue
      # do nothing if trigger doesnt exist
    end
  end
end
