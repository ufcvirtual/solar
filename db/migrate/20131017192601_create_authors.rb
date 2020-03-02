class CreateAuthors < ActiveRecord::Migration[5.0]
  def change
    create_table :authors do |t|
      t.references :bibliography, null: false
      t.foreign_key :bibliographies
      t.string :name, null: false

      t.timestamps
    end
  end
end
