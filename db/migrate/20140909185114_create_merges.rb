class CreateMerges < ActiveRecord::Migration[5.1]
  def change
    create_table :merges do |t|
      t.references :main_group, null: false
      t.references :secundary_group, null: false
      t.boolean :type_merge
      t.datetime :created_at
    end
  end
end
