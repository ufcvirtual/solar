class AddCanPublishToExam < ActiveRecord::Migration[5.0]
  def change
  	add_column :exams, :can_publish, :boolean, default: true
  end
end
