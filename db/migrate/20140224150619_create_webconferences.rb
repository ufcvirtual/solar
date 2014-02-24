class CreateWebconferences < ActiveRecord::Migration
  def change
    create_table :webconferences do |t|
      t.references :user, null: false
      t.foreign_key :users
      t.string :title, null: false
      t.string :description
      t.datetime :initial_time, null: false
      t.integer :duration, null: false

      t.timestamps
    end
  end
end
