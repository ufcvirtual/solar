class CreateMenusContexts < ActiveRecord::Migration
  def self.up
     create_table "menus_contexts", :id => false do |t|
      t.integer "menu_id",    :null => false
      t.integer "context_id", :null => false            
    end
  end

  def self.down
    drop_table "menus_contexts"
  end
end
