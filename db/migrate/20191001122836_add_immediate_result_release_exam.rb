class AddImmediateResultReleaseExam < ActiveRecord::Migration[5.0]
  def change
    change_table :exams do |t|
      t.boolean :immediate_result_release, default: false
    end
  end
end
