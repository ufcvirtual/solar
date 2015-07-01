class AddIndexesToImprovePerformance < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE INDEX group_assignments_academic_allocation_id_idx ON group_assignments (academic_allocation_id);
      CREATE INDEX assignment_comments_sent_assignment_id_idx   ON assignment_comments (sent_assignment_id);
      CREATE INDEX comment_files_assignment_comment_id_idx      ON comment_files (assignment_comment_id);

      DROP INDEX academic_tool_type_idx;
      DROP INDEX academic_tool_id_idx;
      DROP INDEX allocation_tag_id_idx;
      CREATE INDEX academic_allocations_tool_id_type_allocation_tag_id_idx ON academic_allocations (allocation_tag_id, academic_tool_id, academic_tool_type);

      DROP INDEX user_message_message_id_idx;
      DROP INDEX user_message_user_id_idx;
      CREATE INDEX user_messages_user_id_message_id_idx ON user_messages (user_id, message_id);

      CREATE INDEX lessons_lmodule_id ON lessons (lesson_module_id);
      CREATE INDEX allocations_profile_user_allocation_tag_id ON allocations (profile_id, user_id, allocation_tag_id) WHERE status = 1;

      DROP INDEX start_date_idx;
      DROP INDEX end_date_idx;
    SQL
  end

  def down
    ActiveRecord::Base.connection.execute <<-SQL
      DROP INDEX group_assignments_academic_allocation_id_idx;
      DROP INDEX assignment_comments_sent_assignment_id_idx  ;
      DROP INDEX comment_files_assignment_comment_id_idx     ;

      CREATE INDEX academic_tool_type_idx ON academic_allocations (academic_tool_type);
      CREATE INDEX academic_tool_id_idx   ON academic_allocations (academic_tool_id);
      CREATE INDEX allocation_tag_id_idx  ON academic_allocations (allocation_tag_id);
      DROP INDEX academic_allocations_tool_id_type_allocation_tag_id_idx;

      CREATE INDEX user_message_message_id_idx ON user_messages (message_id);
      CREATE INDEX user_message_user_id_idx    ON user_messages (user_id);
      DROP INDEX user_messages_user_id_message_id_idx;
      
      DROP INDEX lessons_lmodule_id;
      DROP INDEX allocations_profile_user_allocation_tag_id;

      CREATE INDEX start_date_idx ON schedules (start_date);
      CREATE INDEX end_date_idx   ON schedules (end_date);
    SQL
  end
end
