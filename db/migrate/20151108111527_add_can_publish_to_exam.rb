class AddCanPublishToExam < ActiveRecord::Migration[5.1]
  def change
  	add_column :exams, :can_publish, :boolean, default: true
  end
end
