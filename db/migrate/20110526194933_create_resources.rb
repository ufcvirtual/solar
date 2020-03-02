class CreateResources < ActiveRecord::Migration[5.0]
  def self.up
    create_table "resources" do |t|
      t.string  "description", :null => false
      t.string  "action",      :null => false
      t.string  "controller",  :null => false
      t.boolean "status",      :default => true
    end
  end

  def self.down
    drop_table "resources"
  end
end
