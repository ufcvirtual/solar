class CreateIpReals < ActiveRecord::Migration
  def change
    create_table :ip_reals do |t|
      t.string :ip_v4
      t.string :ip_v6
      t.references :exam
      t.foreign_key :exams

      t.timestamps
    end
    add_index :ip_reals, :exam_id
  end
end
