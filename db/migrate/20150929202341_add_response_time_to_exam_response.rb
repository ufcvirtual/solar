class AddResponseTimeToExamResponse < ActiveRecord::Migration[5.0]
  def up
    add_column :exam_responses, :response_time, :int, null: true
  end

  def down
    remove_column :exam_responses, :response_time
  end
end
