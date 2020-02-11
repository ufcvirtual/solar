class AddImmediateResultReleaseExam < ActiveRecord::Migration
  def change
    change_table :exams do |t|
      t.boolean :immediate_result_release, default: false
    end
  end
end
