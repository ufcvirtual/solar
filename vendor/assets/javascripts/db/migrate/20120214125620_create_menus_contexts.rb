class CreateMenusContexts < ActiveRecord::Migration
  def self.up
     create_table "menus_contexts", :id => false do |t|
      t.integer "menu_id",    :null => false
      t.integer "context_id", :null => false            
    end

    add_foreign_key(:menus_contexts, :menus)
    add_foreign_key(:menus_contexts, :contexts)
  end

  def self.down
    drop_table "menus_contexts"
  end
end
