class CreateAllocationTagOwners < ActiveRecord::Migration[5.0]
  def change
    create_table :allocation_tag_owners do |t|
      t.references :allocation_tag, null: false
      t.foreign_key :allocation_tags
      t.references :oauth_application, null: false
      t.foreign_key :oauth_applications
    end
  end
end
