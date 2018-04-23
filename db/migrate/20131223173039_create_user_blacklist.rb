class CreateUserBlacklist < ActiveRecord::Migration[5.0]
  def self.up
  	create_table "user_blacklist" do |t|
  		t.string   "cpf", :limit => 14
  		t.string   "name", :limit => 100
    	t.timestamps
    end
  end

  def self.down
  	drop_table "user_blacklist"
  end
end
