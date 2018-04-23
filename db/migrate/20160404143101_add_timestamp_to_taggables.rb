class AddTimestampToTaggables < ActiveRecord::Migration[5.0]
  def change
    [:groups, :offers, :semesters, :courses, :curriculum_units, :curriculum_unit_types].each do |table|
      change_table table do |t|
        t.timestamps
      end
    end
  end
end
