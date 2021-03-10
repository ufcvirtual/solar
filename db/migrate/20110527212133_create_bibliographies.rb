class CreateBibliographies < ActiveRecord::Migration[5.1]
  def self.up
    create_table :bibliographies do |t|
      t.integer :allocation_tag_id, :null => false
      t.string :title
      t.string :additional_text
      t.string :publisher, :limit => 100
      t.string :edition, :limit => 2
      t.string :year, :limit => 4
      t.string :author
      t.string :locale
      t.string :url
      t.string :isbn_issn, :limit => 13
    end

    add_foreign_key :bibliographies, :allocation_tags
  end

  def self.down
    drop_table :bibliographies
  end
end
