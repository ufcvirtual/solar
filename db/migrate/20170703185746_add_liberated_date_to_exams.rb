class AddLiberatedDateToExams < ActiveRecord::Migration[5.0]
  def up
    add_column :exams, :liberated_date, :datetime
  end

  def down
    remove_column :exams, :liberated_date
  end
end
