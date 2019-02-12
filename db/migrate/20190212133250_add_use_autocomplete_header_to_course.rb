class AddUseAutocompleteHeaderToCourse < ActiveRecord::Migration
  def up
    add_column :courses, :use_autocomplete_header, :boolean, default: true, null: false
  end

  def down
    remove_column :courses, :use_autocomplete_header
  end
end
