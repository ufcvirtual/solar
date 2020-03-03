class AddLocationToGroups < ActiveRecord::Migration[5.0]
  def up
    add_column :groups, :location, :string, size: 100
    add_column :groups, :name, :string, size: 100

    Group.joins(offer: :curriculum_unit).where(curriculum_units: {curriculum_unit_type_id: 2}).update_all("name=code")
  end

  def down
    remove_column :groups, :location
    remove_column :groups, :name
  end
end
