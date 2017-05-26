class CreateIpFakes < ActiveRecord::Migration
  def change
    create_table :ip_fakes do |t|
      t.string :ip_v4
      t.string :ip_v6
      t.references :ip_real
      t.foreign_key :ip_reals

      t.timestamps
    end
    add_index :ip_fakes, :ip_real_id
  end
end
