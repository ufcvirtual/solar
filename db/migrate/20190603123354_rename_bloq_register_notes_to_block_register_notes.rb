class RenameBloqRegisterNotesToBlockRegisterNotes < ActiveRecord::Migration[5.0]
  def change
  	rename_column :allocation_tags, :bloq_register_notes, :block_register_notes
  end
end
