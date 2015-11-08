class AddCanPublishToExam < ActiveRecord::Migration
  def change
  	add_column :exams, :can_publish, :boolean, default: true
  end
end
