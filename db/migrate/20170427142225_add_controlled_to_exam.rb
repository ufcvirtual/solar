class AddControlledToExam < ActiveRecord::Migration
  def change
    add_column :exams, :controlled, :boolean, default: false
    add_column :exams, :use_local_network, :boolean, default: false
  end
end
