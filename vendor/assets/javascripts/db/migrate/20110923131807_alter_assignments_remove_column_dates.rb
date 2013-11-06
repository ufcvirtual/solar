class AlterAssignmentsRemoveColumnDates < ActiveRecord::Migration
  def self.up

    change_table :assignments do |t|
      t.remove :start_date
      t.remove :end_date
    end

  end

  def self.down

    change_table :assignments do |t|
      t.datetime :start_date, :null => false
      t.datetime :end_date, :null => false
    end

  end
end
