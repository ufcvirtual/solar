class CreateLogNavigations < ActiveRecord::Migration[5.1]
  def change
    create_table :log_navigations do |t|
      t.integer :user_id
      t.integer :menu_id
      t.integer  :context_id	
      t.datetime :created_at
    end
  end
end
