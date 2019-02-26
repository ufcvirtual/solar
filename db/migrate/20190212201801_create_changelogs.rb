class CreateChangelogs < ActiveRecord::Migration
  def change
    create_table :changelogs do |t|
      t.string :academic_tool_type
      t.text :description
      t.date :deployment
      t.string :author

      t.timestamps
    end
  end
end
