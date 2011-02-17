class CreateTableEnrollmentPeriod < ActiveRecord::Migration
  def self.up
    create_table :enrollment_period do |t|
      t.integer :offer_id, :null => false
      t.date    :start,    :null => false
      t.date    :end,      :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :enrollment_period
  end
end
