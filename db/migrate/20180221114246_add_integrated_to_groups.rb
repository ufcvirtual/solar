class AddIntegratedToGroups < ActiveRecord::Migration[5.0]
  def up
    add_column :groups, :integrated, :boolean, default: false, null: false
    Group.joins(offer: :course).where(courses: {code: ['107', '113', '111', '110', '109', '108', '112', '115', '118']}).update_all integrated: true
  end

  def down
    remove_column :groups, :integrated
  end
end
