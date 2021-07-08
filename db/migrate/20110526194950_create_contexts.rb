class CreateContexts < ActiveRecord::Migration[5.1]
  def self.up
    create_table "contexts" do |t|
      t.string "name",      :limit => 100, :null => false
      t.string "parameter", :limit => 45
    end
  end

  def self.down
    drop_table "contexts"
  end
end
