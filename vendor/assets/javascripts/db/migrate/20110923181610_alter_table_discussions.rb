class AlterTableDiscussions < ActiveRecord::Migration
  def self.up

    change_table :discussions do |t|
      t.remove :start
      t.remove :end
    end

  end

  def self.down
    change_table :discussions do |t|
      t.datetime :start, :null => false
      t.datetime :end, :null => false
    end
  end
end
