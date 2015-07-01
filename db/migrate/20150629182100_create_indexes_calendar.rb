class CreateIndexesCalendar < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE INDEX start_date_idx ON schedules (start_date);
      CREATE INDEX end_date_idx   ON schedules (end_date);

      CREATE INDEX allocation_tag_id_idx  ON academic_allocations (allocation_tag_id);
      CREATE INDEX academic_tool_id_idx   ON academic_allocations (academic_tool_id);
      CREATE INDEX academic_tool_type_idx ON academic_allocations (academic_tool_type);

      CREATE INDEX a_schedule_id_idx  ON assignments (schedule_id);
      CREATE INDEX e_schedule_id_idx  ON exams (schedule_id);
      CREATE INDEX d_schedule_id_idx  ON discussions (schedule_id);
      CREATE INDEX se_schedule_id_idx ON schedule_events (schedule_id);
      CREATE INDEX cr_schedule_id_idx ON chat_rooms (schedule_id);
      CREATE INDEX l_schedule_id_idx  ON lessons (schedule_id);
    SQL
  end

  def down 
    ActiveRecord::Base.connection.execute <<-SQL
      DROP INDEX start_date_idx;
      DROP INDEX end_date_idx;

      DROP INDEX allocation_tag_id_idx;
      DROP INDEX academic_tool_id_idx;
      DROP INDEX academic_tool_type_idx;

      DROP INDEX a_schedule_id_idx;
      DROP INDEX e_schedule_id_idx;
      DROP INDEX d_schedule_id_idx;
      DROP INDEX se_schedule_id_idx;
      DROP INDEX cr_schedule_id_idx;
      DROP INDEX l_schedule_id_idx;
    SQL
  end
end
